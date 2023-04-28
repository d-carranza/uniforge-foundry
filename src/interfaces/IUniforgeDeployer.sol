// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UniforgeDeployer {

    error UniforgeDeployer__NeedMoreETHSent();
    error UniforgeDeployer__TransferFailed();
    error UniforgeDeployer__InvalidDiscount();

    event DeployFeeUpdated(uint256 indexed deployFee);
    event NewCollectionCreated(address indexed collection);
    event NewCreatorDiscount(address indexed creator, uint256 indexed discount);

    function deployNewCollection(
        address owner,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 mintFee,
        uint256 mintLimit,
        uint256 maxSupply,
        uint256 saleStart,
        uint96 royaltyPercentage,
        bool royaltyEnforced
    ) external payable;

    function setDeployFee(uint256 fee) external;
    
    function setCreatorDiscount(address creator, uint256 percentage) external;

    function withdraw() external;
    
    function deployments() external view;
    
    function deployment(uint256 index) external view;
    
    function deployFee() external view;
    
    function creatorDiscount(address creator) external view;
    
    function creatorFee(address creator) external view;
}