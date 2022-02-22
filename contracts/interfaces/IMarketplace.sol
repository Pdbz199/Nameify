// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IMarketplace {
    function listUsername(uint256 _price) external;
    function unlistUsername() external;
    function listingPrice(string calldata _username) external view returns(uint256);
    function buyUsername(string calldata _username) external payable;
    function makeBid(string calldata _username) external;
    function removeBid(string calldata _username) external;
    function acceptBid() external;
}