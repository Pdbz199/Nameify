// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import { Registry } from './Registry.sol';
import { IMarketplace } from './interfaces/IMarketplace.sol';

contract Marketplace is Registry, IMarketplace {
    // STORAGE
    mapping(string => uint256) private usernamePrices;
    mapping(string => mapping(address => uint256)) private bidAmount;
    mapping(string => uint256) private largestBid;
    mapping(string => address) private largestBidder;

    // ERRORS
    error UsernameHasNotBeenListed();
    error PriceNotHighEnoughToPurchaseUsername(uint256 price, string username);
    error FailedToSendCrypto();
    error TxOriginIsNotOwnerOfUsername();

    // MODIFIERS
    modifier usernameIsListed(string memory _username) {
        if (usernamePrices[_username] == 0) {
            revert UsernameHasNotBeenListed();
        }
        _;
    }

    // FUNCTIONS
    function listUsername(uint256 _price) external {
        usernamePrices[addressToUsername[tx.origin]] = _price;
    }

    function unlistUsername() external usernameIsListed(addressToUsername[tx.origin]) {
        usernamePrices[addressToUsername[tx.origin]] = 0;
    }

    function listingPrice(string calldata _username) external view returns(uint256) {
        return usernamePrices[_username];
    }

    function buyUsername(string calldata _username) external payable usernameIsListed(_username) {
        if (msg.value < usernamePrices[_username]) {
            revert PriceNotHighEnoughToPurchaseUsername(msg.value, _username);
        }

        bool success = payable(usernameToAddress[_username]).send(msg.value);
        if (!success) {
            revert FailedToSendCrypto();
        }

        usernamePrices[_username] = 0;

        addressToUsername[usernameToAddress[_username]] = "";
        usernameToAddress[_username] = tx.origin;
        addressToUsername[tx.origin] = _username;
    }

    function makeBid(string calldata _username) external {
        // bidAmount[_username][tx.origin] += msg.value;

        // if (bidAmount[_username][tx.origin] > largestBid) {
        //     largestBid[_username] = bidAmount[_username][tx.origin];
        //     largestBidder[_username] = tx.origin;
        // }
    }

    function removeBid(string calldata _username) external {
        // bool success = payable(tx.origin).send(bidAmount[_username][tx.origin]);
        // if (!success) {
        //     revert FailedToSendCrypto();
        // }
        // if (bidAmount)
        // bidAmount[_username][tx.origin] = 0;
    }

    function acceptBid() external {
        // code
    }
}