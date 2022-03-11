// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import { Registry } from './Registry.sol';
import { IMarketplace } from './interfaces/IMarketplace.sol';

contract Marketplace is Registry, IMarketplace {
    /* STORAGE */

    mapping(string => uint256) private usernamePrices;
    mapping(address => mapping(string => uint256)) private bidAmount;
    mapping(string => uint256) private highestBid;
    mapping(string => address) private highestBidder;

    /* ERRORS */

    error UsernameHasNotBeenListed();
    error PriceNotHighEnoughToPurchaseUsername(uint256 price, string username);
    error FailedToSendCrypto();
    error TxOriginIsNotOwnerOfUsername();
    error UsernameIsNotOwnedByAnyAddress(string username);
    error CurrentBidNotHigherThanHighestBid(uint256 currentBid, uint256 highestBid);
    error NoBidToRemove(address sender, string username);
    error ErrorSendingBidAmountToSender();
    error ThereIsNoHighestBidder();

    /* MODIFIERS */

    modifier usernameIsListed(string memory _username) {
        if (usernamePrices[_username] == 0) {
            revert UsernameHasNotBeenListed();
        }
        _;
    }

    /* FUNCTIONS */

    function listUsername(uint256 _price) external override {
        usernamePrices[addressToUsername[msg.sender]] = _price;
    }

    function unlistUsername() external usernameIsListed(addressToUsername[msg.sender]) override {
        usernamePrices[addressToUsername[msg.sender]] = 0;
    }

    function listingPrice(string calldata _username) external view override returns(uint256) {
        return usernamePrices[_username];
    }

    function buyUsername(string calldata _username) external payable usernameIsListed(_username) override {
        if (msg.value < usernamePrices[_username]) {
            revert PriceNotHighEnoughToPurchaseUsername(msg.value, _username);
        }

        bool success = payable(usernameToAddress[_username]).send(msg.value);
        if (!success) {
            revert FailedToSendCrypto();
        }

        usernamePrices[_username] = 0;

        addressToUsername[usernameToAddress[_username]] = "";
        usernameToAddress[_username] = msg.sender;
        addressToUsername[msg.sender] = _username;
    }

    function makeBid(string calldata _username) external payable override {
        // If no one owns the address, revert
        if (usernameToAddress[_username] == address(0)) {
            revert UsernameIsNotOwnedByAnyAddress(_username);
        }

        // Update msg.sender's bid amount for _username
        bidAmount[msg.sender][_username] += msg.value;

        // If new bid amount is less than or equal to highest bid, revert
        if (bidAmount[msg.sender][_username] <= highestBid[_username]) {
            revert CurrentBidNotHigherThanHighestBid(bidAmount[msg.sender][_username], highestBid[_username]);
        }

        // Update highest bid information
        highestBidder[_username] = msg.sender;
        highestBid[_username] = bidAmount[msg.sender][_username];
    }

    function removeBid(string calldata _username) external override {
        // If no bid amount, revert
        if (bidAmount[msg.sender][_username] == 0) {
            revert NoBidToRemove(msg.sender, _username);
        }

        // Try to transfer out their amount. If unsuccessful, revert
        bool success = payable(msg.sender).send(bidAmount[msg.sender][_username]);
        if (!success) {
            revert ErrorSendingBidAmountToSender();
        }

        // Update bidAmount
        bidAmount[msg.sender][_username] == 0;

        // If the highest bidder is removing their bid, reset highest bid vars
        if (highestBidder[_username] == msg.sender) {
            highestBidder[_username] = address(0);
            highestBid[_username] = 0;
        }
    }

    function updateHighestBid(string calldata _username) external override {
        // If current bid amount is less than or equal to highest bid, revert
        if (bidAmount[msg.sender][_username] <= highestBid[_username]) {
            revert CurrentBidNotHigherThanHighestBid(bidAmount[msg.sender][_username], highestBid[_username]);
        }

        // Update highest bid information
        highestBidder[_username] = msg.sender;
        highestBid[_username] = bidAmount[msg.sender][_username];
    }

    function getBidAmount(string calldata _username) external view override returns(uint256) {
        return bidAmount[msg.sender][_username];
    }

    function getHighestBidAmount(string calldata _username) external view override returns(uint256) {
        return highestBid[_username];
    }

    function acceptHighestBid() external override {
        string memory username = addressToUsername[msg.sender];

        // If no one is highest bidder or if highest bid amount is zero, revert
        if (highestBidder[username] == address(0) || highestBid[username] == 0) {
            revert ThereIsNoHighestBidder();
        }

        // Try to send bid amount to owner of username. If unsuccessful, revert
        bool success = payable(msg.sender).send(highestBid[username]);
        if (!success) {
            revert ErrorSendingBidAmountToSender();
        }

        // Update the registry mappings
        addressToUsername[msg.sender] = "";
        addressToUsername[highestBidder[username]] = username;
        usernameToAddress[username] = highestBidder[username];

        // Update highest bidder mappings
        highestBidder[username] = address(0);
        highestBid[username] = 0;
    }
}