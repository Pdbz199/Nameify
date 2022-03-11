// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IMarketplace {
    /**
     * @notice List your username for a given price
     * @param _price Amount of crypto for username to be priced at
     */
    function listUsername(uint256 _price) external;

    /**
     * @notice Unlist your username from the marketplace
     */
    function unlistUsername() external;

    /**
     * @notice Get listing price of a specified username
     * @param _username Username string
     * @return Listing price of _username
     */
    function listingPrice(string calldata _username) external view returns(uint256);

    /**
     * @notice Purchase a given username for the listed price
     * @param _username Username string
     * @dev This function requires msg.value >= listingPrice
     */
    function buyUsername(string calldata _username) external payable;

    /**
     * @notice Place a bid on a particular username
     * @param _username Username string
     * @dev The bid amount is msg.value
     * @dev If there was a previous bid, the new msg.value will be added to the old bid amount
     */
    function makeBid(string calldata _username) external payable;

    /**
     * @notice Remove all of msg.sender's bid amount for a particular username and send it back
     * @param _username Username string
     */
    function removeBid(string calldata _username) external;

    /**
     * @notice Update the highest bid mapping for a given username based on msg.sender's current bid
     * @param _username Username string
     * @dev This is meant to be used by the second highest bidder if the highest bidder removes their bid
     */
    function updateHighestBid(string calldata _username) external;

    /**
     * @notice See msg.sender's bid amount for a given username
     * @param _username Username string
     */
    function getBidAmount(string calldata _username) external view returns(uint256);

    /**
     * @notice See highest bid amount for a given username
     * @param _username Username string
     */
    function getHighestBidAmount(string calldata _username) external view returns(uint256);

    /**
     * @notice Accept the highest bid on your username
     * @dev This will not accept any bid with 0 value
     */
    function acceptHighestBid() external;
}