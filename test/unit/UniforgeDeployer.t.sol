// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "src/UniforgeDeployer.sol";
import "src/UniforgeCollection.sol";

contract UniforgeDeployerTest is Test {
    UniforgeDeployer public uniforgeDeployer;

    address firstNewCollectionAddress =
        0x104fBc016F4bb334D775a19E8A6510109AC63E00;
    address deployer = 0x710E272C2052eEfa1a1A67ef347D19B9fE4bEc75;
    address owner = 0x46ac62Ea156A7476b087B986Ea312Bae06279A0C;

    event NewCollectionCreated(address indexed newERC721Uniforge);
    event DeployFeeUpdated(uint256 indexed newDeployFee);

    function setUp() public {
        uniforgeDeployer = new UniforgeDeployer(owner);
        vm.deal(deployer, 1e18);
    }

    function test_Constructor_DeployerBecomesOwner() public {
        assertEq(uniforgeDeployer.owner(), owner);
    }

    function test_DeployNewCollection_EmitsCreationEvent() public {
        vm.expectEmit(true, false, false, false);
        emit NewCollectionCreated(
            address(0x104fBc016F4bb334D775a19E8A6510109AC63E00)
        );
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection(
            owner,
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

    function test_DeployNewCollection_CounterGoesUp() public {
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection(
            owner,
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
        assertEq(uniforgeDeployer.deployments(), 1);
    }

    function test_DeployNewCollection_AddedToMapping() public {
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection(
            owner,
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
        assertEq(
            uniforgeDeployer.deployment(0),
            address(0x104fBc016F4bb334D775a19E8A6510109AC63E00)
        );
    }

    function test_DeployNewCollection_ZeroEthReverts() public {
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(1e16);

        vm.expectRevert(UniforgeDeployer__NeedMoreETHSent.selector);
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection(
            owner,
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

    function test_DeployNewCollection_LessEthReverts() public {
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(1e16);

        vm.expectRevert(UniforgeDeployer__NeedMoreETHSent.selector);
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection(
            owner,
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

    function test_DeployNewCollection_ExactEthSucceeds() public {
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(1e16);

        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection{value: 1e16}(
            owner,
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
        assertEq(address(uniforgeDeployer).balance, 1e16);
    }

    function test_DeployNewCollection_MoreEthSucceeds() public {
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(1e16);

        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection{value: 1e18}(
            owner,
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
        assertEq(address(uniforgeDeployer).balance, 1e18);
    }

    function test_SetDeployFee_OwnerUpdatesFee() public {
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(1e16);
        assertEq(uniforgeDeployer.deployFee(), 1e16);
    }

    function test_SetDeployFee_NotOwnerReverts() public {
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeDeployer.setDeployFee(1e16);
    }

    function test_SetDeployFee_UpdateEmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit DeployFeeUpdated(1e16);
        uniforgeDeployer.setDeployFee(1e16);
    }

    function test_SetCreatorDiscount_UpdateAllowsDiscount() public {
        vm.deal(deployer, 1e18);

        vm.startPrank(owner);
        uniforgeDeployer.setDeployFee(10 * 1e17);
        uniforgeDeployer.setCreatorDiscount(deployer, 20);
        vm.stopPrank();

        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection{value: 8 * 1e17}(
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

        assertEq(uniforgeDeployer.deployments(), 1);
    }

    function test_SetCreatorDiscount_InvalidDiscountReverts() public {
        vm.deal(deployer, 1e18);

        vm.startPrank(owner);
        uniforgeDeployer.setDeployFee(10 * 1e17);
        vm.expectRevert(UniforgeDeployer__InvalidDiscount.selector);
        uniforgeDeployer.setCreatorDiscount(deployer, 100);
    }

    function test_SetCreatorDiscount_NotOwnerReverts() public {
        vm.deal(deployer, 1e18);

        vm.startPrank(deployer);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeDeployer.setDeployFee(10 * 1e17);
    }

    function test_Withdraw_OwnerWithdrawSuccessfully() public {
        uint256 initialBalance = owner.balance;
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection{value: 1e18}(
            owner,
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
        vm.prank(owner);
        uniforgeDeployer.withdraw();
        assertEq(owner.balance, initialBalance + 1e18);
    }

    function test_Withdraw_NotOwnerReverts() public {
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeDeployer.withdraw();
    }

    function test_Withdraw_FailedCallReverts() public {
        vm.prank(owner);
        uniforgeDeployer.transferOwnership(address(this));
        vm.prank(address(this));
        vm.expectRevert(UniforgeDeployer__TransferFailed.selector);
        uniforgeDeployer.withdraw();
    }

    function test_deployments() public {
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection(
            owner,
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
        assertEq(uniforgeDeployer.deployments(), 1);
    }

    function test_deployment() public {
        vm.prank(deployer);
        uniforgeDeployer.deployNewCollection(
            owner,
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
        assertEq(uniforgeDeployer.deployment(0), firstNewCollectionAddress);
    }

    function test_deployFee() public {
        vm.prank(owner);
        uniforgeDeployer.setDeployFee(1e16);
        assertEq(uniforgeDeployer.deployFee(), 1e16);
    }

    function test_discountForAddress() public {
        vm.prank(owner);
        uniforgeDeployer.setCreatorDiscount(deployer, 10);
        assertEq(uniforgeDeployer.creatorDiscount(deployer), 10);
    }

    function test_priceForAddress() public {
        vm.startPrank(owner);
        uniforgeDeployer.setDeployFee(10 * 1e17);
        uniforgeDeployer.setCreatorDiscount(deployer, 10);

        assertEq(uniforgeDeployer.creatorFee(deployer), 9 * 1e17);
    }
}
