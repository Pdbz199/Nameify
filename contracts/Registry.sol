// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import { IRegistry } from './interfaces/IRegistry.sol';

contract Registry is IRegistry {
    // STORAGE
    mapping(address => string) private addressToUsername;
    mapping(string => address) private usernameToAddress;
    mapping(string => bool) private usernameExists;
    mapping(string => uint256) private usernamePrices;

    // ERRORS
    error UsernameAlreadyExists(string username);
    error UsernameCannotBeEmptyString();
    error AccountDoesNotHaveAUsername(address account);
    error UsernameHasNotBeenSet(string username);
    error UsernameHasNotBeenListed();
    error PriceNotHighEnoughToPurchaseUsername(uint256 price, string username);
    error FailedToSendCrypto();

    // MODIFIERS
    modifier usernameDoesNotExist(string calldata _username) {
        if (usernameExists[_username]) {
            revert UsernameAlreadyExists(_username);
        }
        _;
    }

    modifier checkUsername(string calldata _username) {
        if (bytes(_username).length == 0) {
            revert UsernameCannotBeEmptyString();
        }
        _;
    }

    modifier accountHasUsername(address _account) {
        if (!usernameExists[addressToUsername[_account]]) {
            revert AccountDoesNotHaveAUsername(_account);
        }
        _;
    }

    modifier usernameIsListed(string memory _username) {
        if (usernamePrices[_username] == 0) {
            revert UsernameHasNotBeenListed();
        }
        _;
    }

    // FUNCTIONS
    function setUsername(string calldata _username) external
        usernameDoesNotExist(_username)
        checkUsername(_username)
    {
        usernameExists[addressToUsername[tx.origin]] = false;
        usernameExists[_username] = true;

        usernameToAddress[addressToUsername[tx.origin]] = address(0);
        usernameToAddress[_username] = tx.origin;
        
        addressToUsername[tx.origin] = _username;
    }

    function removeUsername() external
        accountHasUsername(tx.origin)
    {
        usernameExists[addressToUsername[tx.origin]] = false;
        usernameToAddress[addressToUsername[tx.origin]] = address(0);
        addressToUsername[tx.origin] = "";
    }

    function listUsername(
        uint256 _price
    ) external accountHasUsername(tx.origin) {
        usernamePrices[addressToUsername[tx.origin]] = _price;
    }

    function listingPrice(string calldata _username) external view returns(uint256) {
        return usernamePrices[_username];
    }

    function unlistUsername() external
        usernameIsListed(addressToUsername[tx.origin])
    {
        usernamePrices[addressToUsername[tx.origin]] = 0;
    }

    function buyUsername(
        string calldata _username
    ) external payable usernameIsListed(_username) {
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

    function getUsername(
        address _account
    ) external accountHasUsername(_account) view returns(string memory) {
        return addressToUsername[_account];
    }

    function getAddress(string calldata _username) external view returns(address) {
        address account = usernameToAddress[_username];
        if (account == address(0)) {
            revert UsernameHasNotBeenSet(_username);
        }
        return account;
    }
}