// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UniforgeCollection {
    error UniforgeCollection__LockedBaseURI();
    error UniforgeCollection__TransferFailed();
    error UniforgeCollection__MaxSupplyExceeded();
    error UniforgeCollection__InvalidMintAmount();
    error UniforgeCollection__NeedMoreETHSent();
    error UniforgeCollection__SaleIsNotOpen();

    event RoyaltyEnforced(bool indexed enforced);
    event BaseURIUpdated(string indexed baseURI);
    event MintFeeUpdated(uint256 indexed mintFee);
    event SaleStartUpdated(uint256 indexed saleStart);
    event RoyaltyUpdated(address indexed royaltyReceiver, uint96 indexed royaltyPercentage);

    function mintNft(uint256 quantity) external payable;

    function creatorMint(address receiver, uint256 quantity) external;

    function setSaleStart(uint256 timestamp) external;

    function setMintFee(uint256 newMintFee) external;

    function withdraw() external;

    function setBaseURI(string memory newBaseURI) external;

    function lockBaseURI() external;

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    function toggleRoyaltyEnforcement() external;

    function setApprovalForAll(address operator, bool approved) external;

    function approve(address operator, uint256 tokenId) external payable;

    function transferFrom(address from, address to, uint256 tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable;

    function supportsInterface(bytes4 interfaceId) external view;

    function baseURI() external view;

    function lockedBaseURI() external view;

    function maxSupply() external view;
    
    function mintFee() external view;
    
    function mintLimit() external view;
    
    function saleStart() external view;
    
    function royaltyReceiver() external view;
    
    function royaltyPercentage() external view;
    
    function royaltyEnforced() external view;
}