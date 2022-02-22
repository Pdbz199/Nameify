// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IRegistry {
    /**
     * @notice Sets the username for the sender of the transaction
     * @param _username Username that will be tied to tx.origin
     */
    function setUsername(string calldata _username) external;

    /**
     * @notice Removes the username from the sender of the transaction
     */
    function removeUsername() external;

    /**
     * @notice Get username given account address
     * @param _account Account address
     * @return Username of _account
     */
    function getUsername(address _account) external view returns(string calldata);

    /**
     * @notice Get account address given account username
     * @param _username Username of desired account address
     * @return Account address whose username is _username
     */
    function getAddress(string calldata _username) external view returns(address);
}