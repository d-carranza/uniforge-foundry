// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "src/UniforgeDeployer.sol";
import "src/UniforgeCollection.sol";

contract UniforgeDeployerFuzzTest is Test {
    UniforgeDeployer public uniforgeDeployer;
    UniforgeCollection public uniforgeCollection;

    address firstNewCollectionAddress =
        0x104fBc016F4bb334D775a19E8A6510109AC63E00;
    address deployer = makeAddr("deployer");
    address owner = makeAddr("owner");

    event NewCollectionCreated(address indexed newUniforgeCollection);
    event DeployFeeUpdated(uint256 indexed newDeployFee);

    function setUp() public {
        uniforgeDeployer = new UniforgeDeployer(owner);
        vm.deal(deployer, 1e18);
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(1e16);
    }

    function testFuzz_deployNewCollection(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint128 _mintFee,
        uint128 _maxBatchMint,
        uint128 _maxSupply,
        uint256 _saleStart,
        uint96 _royaltyPercentage,
        bool _royaltyEnforced
    ) public {
        vm.assume(_owner != address(0));
        vm.assume(_royaltyPercentage <= 10000);

        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection{value: 1e16}(
            _owner,
            _name,
            _symbol,
            _baseURI,
            _mintFee,
            _maxBatchMint,
            _maxSupply,
            _saleStart,
            _royaltyPercentage,
            _royaltyEnforced
        );
        assertEq(uniforgeDeployer.deployments(), 1);
    }

    function testFuzz_SetDeployFee_Owner(uint256 _deployFee) public {
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(_deployFee);
        assertEq(uniforgeDeployer.deployFee(), _deployFee);
    }

    function testFuzz_SetDeployerDiscount_Owner(
        address _customer,
        uint256 _discountPercentage
    ) public {
        vm.assume(_discountPercentage < 100);
        vm.prank(owner);
        uniforgeDeployer.setCreatorDiscount(_customer, _discountPercentage);
        assertEq(uniforgeDeployer.creatorDiscount(_customer), _discountPercentage);
    }

    function testFuzz_deployment(uint256 _index) public {
        vm.assume(_index < 10);
        for (uint256 i = 0; i <= _index; i++) {
            vm.deal(deployer, 1e18);
            vm.prank(deployer);
            uniforgeDeployer.deployNewCollection{value: 1e16}(
                deployer,
                "Dappenics",
                "DAPE",
                "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/",
                1e16,
                2,
                10000,
                10000000,
                100,
                false
            );
        }
    }

    function testFuzz_discountForAddress(address _customer) public {
        vm.prank(owner);
        uniforgeDeployer.setCreatorDiscount(_customer, 30);
        assertEq(uniforgeDeployer.creatorDiscount(_customer), 30);
    }

    function testFuzz_priceForAddress(address _customer) public {
        vm.prank(owner);
        uniforgeDeployer.setCreatorDiscount(_customer, 30);
        assertEq(uniforgeDeployer.creatorFee(_customer), 7 * 1e15);
    }
}
