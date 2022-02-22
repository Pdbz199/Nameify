// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import { IRegistry } from './interfaces/IRegistry.sol';

contract Registry is IRegistry {
    // STORAGE
    mapping(address => string) internal addressToUsername;
    mapping(string => address) internal usernameToAddress;
    mapping(string => bool) internal usernameExists;

    // ERRORS
    error UsernameAlreadyExists();
    error UsernameCannotBeEmptyString();
    error AccountDoesNotHaveAUsername();
    error UsernameHasNotBeenSet();

    // MODIFIERS
    modifier usernameDoesNotExist(string calldata _username) {
        if (usernameExists[_username]) {
            revert UsernameAlreadyExists();
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
            revert AccountDoesNotHaveAUsername();
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

    function getUsername(address _account) external
        accountHasUsername(_account)
        view returns(string memory)
    {
        return addressToUsername[_account];
    }

    function getAddress(string calldata _username) external view returns(address) {
        address account = usernameToAddress[_username];
        if (account == address(0)) {
            revert UsernameHasNotBeenSet();
        }
        return account;
    }
}