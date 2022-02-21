// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import { IRegistry } from './interfaces/IRegistry.sol';

contract Registry is IRegistry {
    // STORAGE
    mapping(address => string) private addressToUsername;
    mapping(string => address) private usernameToAddress;
    mapping(string => bool) private usernameExists;

    // ERRORS
    error UsernameAlreadyExists(string username);
    error UsernameCannotBeEmptyString();
    error AccountDoesNotHaveAUsername(address account);
    error UsernameHasNotBeenSet(string username);

    // MODIFIERS
    modifier checkUsername(string calldata _username) {
        if (usernameExists[_username]) {
            revert UsernameAlreadyExists(_username);
        }
        if (bytes(_username).length == 0) {
            revert UsernameCannotBeEmptyString();
        }
        _;
    }

    modifier checkAccount(address _account) {
        if (!usernameExists[addressToUsername[_account]]) {
            revert AccountDoesNotHaveAUsername(_account);
        }
        _;
    }

    // FUNCTIONS
    function setUsername(string calldata _username) external checkUsername(_username) {
        usernameExists[addressToUsername[tx.origin]] = false;
        usernameExists[_username] = true;
        usernameToAddress[_username] = tx.origin;
        addressToUsername[tx.origin] = _username;
    }

    function removeUsername() external
        checkAccount(tx.origin)
    {
        usernameExists[addressToUsername[tx.origin]] = false;
        usernameToAddress[addressToUsername[tx.origin]] = address(0);
        addressToUsername[tx.origin] = "";
    }

    function getUsername(address _account) external view returns(string memory) {
        string memory username = addressToUsername[_account];
        if (bytes(username).length == 0) {
            revert AccountDoesNotHaveAUsername(tx.origin);
        }
        return username;
    }

    function getAddress(string calldata _username) external view returns(address) {
        address account = usernameToAddress[_username];
        if (account == address(0)) {
            revert UsernameHasNotBeenSet(_username);
        }
        return account;
    }
}