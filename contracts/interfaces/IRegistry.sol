// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IRegistry {
    function setUsername(string calldata username) external;
    function getUsername(address account) external view returns(string calldata);
    function getAddress(string calldata username) external view returns(address);
}