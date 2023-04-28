// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "src/UniforgeCollection.sol";
import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";


contract UniforgeCollectionForkTest is Test {
    UniforgeCollection public uniforgeCollection;

    uint256 ethereumFork;
    string MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    address coriSubscription = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    address deployer = makeAddr("deployer");
    address owner = makeAddr("owner");
    address minter = makeAddr("minter");
    address holder = makeAddr("holder");
    address blockedOperator = 0xFED24eC7E22f573c2e08AEF55aA6797Ca2b3A051;
    address notBlockedOperator = makeAddr("notFilterOperator");
    address filterRegistryAddress = 0x000000000000AAeB6D7670E522A718067333cd4E;

    event MintFeeUpdated(uint256 indexed mintFee);
    event BaseURIUpdated(string indexed baseURI);
    event RoyalityRecipientUpdated(address indexed royaltyAddress);
    event RoyalitiesEnforced(bool indexed enabled);

    function setUp() public {
        ethereumFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(ethereumFork);
        
        vm.prank(deployer);
        uniforgeCollection = new UniforgeCollection(
            owner,
            "Dappenics",
            "DAPE",
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/",
            1e16,
            10,
            10000,
            2,
            420,
            false
        );
        deal(minter, 1e20);
        vm.warp(3);
    }

    function testFork_Constructor_DeployerBecomesOwner() public {
        assertEq(uniforgeCollection.owner(), owner);
    }

    function testFork_Constructor_BaseURIStored() public {
        assertEq(
            uniforgeCollection.baseURI(),
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/"
        );
    }

    function testFork_Constructor_MintFeeStored() public {
        assertEq(uniforgeCollection.mintFee(), 1e16);
    }

    function testFork_Constructor_MaxMintAmountStored() public {
        assertEq(uniforgeCollection.mintLimit(), 10);
    }

    function testFork_Constructor_MaxSupplyStored() public {
        assertEq(uniforgeCollection.maxSupply(), 10000);
    }

    function testFork_Constructor_SaleStartStored() public {
        assertEq(uniforgeCollection.saleStart(), 2);
    }

    function testFork_MintNft_ZeroMintAmountReverts() public {
        vm.prank(minter);
        vm.expectRevert();
        uniforgeCollection.mintNft(0);
    }

    function testFork_MintNft_LessMintAmount() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function testFork_MintNft_EqualMintAmount() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 2 * 1e16}(2);
        assertEq(uniforgeCollection.totalSupply(), 2);
    }

    function testFork_MintNft_MoreMintAmountReverts() public {
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__InvalidMintAmount.selector);
        uniforgeCollection.mintNft{value: 11 * 1e16}(11);
    }

    function testFork_MintNft_ClosedSaleReverts() public {
        vm.warp(1);
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__SaleIsNotOpen.selector);
        uniforgeCollection.mintNft{value: 1e16}(1);
    }

    function testFork_MintNft_ZeroEthReverts() public {
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__NeedMoreETHSent.selector);
        uniforgeCollection.mintNft(1);
    }

    function testFork_MintNft_ZeroEthSucceedsWhenMintFeeZero() public {
        vm.prank(owner);
        uniforgeCollection.setMintFee(0);
        vm.prank(minter);
        uniforgeCollection.mintNft(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function testFork_MintNft_LessEthReverts() public {
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__NeedMoreETHSent.selector);
        uniforgeCollection.mintNft{value: 1e15}(1);
    }

    function testFork_MintNft_EqualEth() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function testFork_MintNft_MoreEth() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e17}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function testFork_MintNFT_RevertsWhenMintMoreThanSupply() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(msg.sender, 10000);
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__MaxSupplyExceeded.selector);
        uniforgeCollection.mintNft{value: 1e17}(1);
    }

    function testFork_CreatorMint_OwnerMintsSelf() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(msg.sender, 1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function testFork_CreatorMint_OwnerMintsToOther() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(minter, 1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function testFork_CreatorMint_OwnerMintsMore() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(msg.sender, 5);
        assertEq(uniforgeCollection.totalSupply(), 5);
    }

    function testFork_CreatorMint_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.creatorMint(minter, 5);
    }

    function testFork_CreatorMint_RevertsWhenMintMoreThanSupply() public {
        vm.startPrank(owner);
        vm.expectRevert(UniforgeCollection__MaxSupplyExceeded.selector);
        uniforgeCollection.creatorMint(msg.sender, 10001);
    }

    function testFork_Withdraw_OwnerWithdrawSuccessfully() public {
        uint256 initialBalance = owner.balance;
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        vm.prank(owner);
        uniforgeCollection.withdraw();
        assertEq(owner.balance, initialBalance + 1e16);
    }

    function testFork_Withdraw_NotOwnerReverts() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.withdraw();
    }

    function testFork_Withdraw_FailedCallReverts() public {
        vm.prank(owner);
        uniforgeCollection.transferOwnership(address(this));
        vm.prank(address(this));
        vm.expectRevert(UniforgeCollection__TransferFailed.selector);
        uniforgeCollection.withdraw();
    }

    function testFork_SetMintFee_OwnerUpdatesFee() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit MintFeeUpdated(1e18);
        uniforgeCollection.setMintFee(1e18);
        assertEq(uniforgeCollection.mintFee(), 1e18);
    }

    function testFork_SetMintFee_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.setMintFee(1e18);
    }

    function testFork_SetBaseURI_OwnerUpdatesBaseURI() public {
        vm.prank(owner);
        uniforgeCollection.setBaseURI("hello");
        assertEq(uniforgeCollection.baseURI(), "hello");
    }

    function testFork_SetBaseURI_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.setBaseURI("hello");
    }

    function testFork_SetBaseURI_LockedBaseURIReverts() public {
        vm.startPrank(owner);
        uniforgeCollection.lockBaseURI();
        vm.expectRevert(UniforgeCollection__LockedBaseURI.selector);
        uniforgeCollection.setBaseURI("hello");
    }

    function testFork_LockBaseURI_OwnerLocksBaseURI() public {
        vm.prank(owner);
        uniforgeCollection.lockBaseURI();
        assertEq(uniforgeCollection.lockedBaseURI(), true);
    }

     function testFork_LockBaseURI_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.lockBaseURI();
    }

    function testFork_SetDefaultRoyalty_OwnerUpdatesDefaultRoyalty() public {
        vm.startPrank(owner);
        uniforgeCollection.creatorMint(minter, 10);
        uniforgeCollection.setDefaultRoyalty(minter, 690);
        (address reciever, uint256 fee) = uniforgeCollection.royaltyInfo(0, 1000);
        assertEq(reciever, minter); 
        assertEq(fee, 69); 
    }

     function testFork_SetDefaultRoyalty_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.setDefaultRoyalty(minter, 690);
    }

    // function testFork_DeleteDefaultRoyalty_OwnerDeletesDefaultRoyalty() public {
    //     vm.startPrank(owner);
    //     uniforgeCollection.creatorMint(minter, 10);
    //     uniforgeCollection.deleteDefaultRoyalty();
    //      (address reciever, uint256 fee) = uniforgeCollection.royaltyInfo(0, 1000);
    //     assertEq(reciever, address(0)); 
    //     assertEq(fee, 0); 
    // }

    //  function testFork_DeleteDefaultRoyalty_NotOwnerReverts() public {
    //     vm.prank(minter);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     uniforgeCollection.setDefaultRoyalty(minter, 690);
    // }

     function testFork_ToggleRoyaltyEnforcement_OwnerTogglesFilter() public {
        // User approves blocked operator when filter is off.
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 5 * 1e16}(5);
        assertEq(uniforgeCollection.royaltyEnforced(), false);
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        assertEq(uniforgeCollection.isApprovedForAll(minter, blockedOperator), true);
        vm.stopPrank();
        
        // Reverts when user approves blocked operator when filter is on.
        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();
        vm.prank(minter);
        vm.expectRevert();
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
    }

     function testFork_ToggleRoyaltyEnforcement_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.toggleRoyaltyEnforcement();
    }

    function testFork_SetApprovalForAll_FilterOFFMinterApprovesNotBlockedOperator() public {
        vm.startPrank(minter);
        assertEq(uniforgeCollection.isApprovedForAll(minter, notBlockedOperator), false);
        uniforgeCollection.mintNft{value: 5 * 1e16}(5);
        // Approves
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        assertEq(uniforgeCollection.isApprovedForAll(minter, notBlockedOperator), true);
        // Disapproves
        uniforgeCollection.setApprovalForAll(notBlockedOperator, false);
        assertEq(uniforgeCollection.isApprovedForAll(minter, notBlockedOperator), false);
    }

    function testFork_SetApprovalForAll_FilterOFFMinterApprovesBlockedOperator() public {
        vm.startPrank(minter);
        assertEq(uniforgeCollection.isApprovedForAll(minter, blockedOperator), false);
        uniforgeCollection.mintNft{value: 5 * 1e16}(5);
        // Approves
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        assertEq(uniforgeCollection.isApprovedForAll(minter, blockedOperator), true);
        // Disapproves
        uniforgeCollection.setApprovalForAll(blockedOperator, false);
        assertEq(uniforgeCollection.isApprovedForAll(minter, blockedOperator), false);
    }

    function testFork_SetApprovalForAll_FilterONMinterApprovesNotBlockedOperator() public {
        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.startPrank(minter);
        assertEq(uniforgeCollection.isApprovedForAll(minter, notBlockedOperator), false);
        uniforgeCollection.mintNft{value: 5 * 1e16}(5);

        // Approves
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        assertEq(uniforgeCollection.isApprovedForAll(minter, notBlockedOperator), true);
        // Disapproves
        uniforgeCollection.setApprovalForAll(notBlockedOperator, false);
        assertEq(uniforgeCollection.isApprovedForAll(minter, notBlockedOperator), false);
    }

    function testFork_SetApprovalForAll_FilterONMinterAprovesBlockedOperator() public {
        assertEq(uniforgeCollection.isApprovedForAll(minter, blockedOperator), false);

        vm.prank(minter);
        uniforgeCollection.mintNft{value: 5 * 1e16}(5);

        // Enforcement ON
        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        // Reverts
        vm.prank(minter);
        vm.expectRevert();
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
    }

    function testFork_Approve_FilterOFFMinterApprovesNotBlockedOperator() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.getApproved(0), address(0));
        // Approves
        uniforgeCollection.approve(notBlockedOperator, 0);
        assertEq(uniforgeCollection.getApproved(0), notBlockedOperator);
    }

    function testFork_Approve_FilterOFFMinterApprovesBlockedOperator() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.getApproved(0), address(0));
        // Approves
        uniforgeCollection.approve(blockedOperator, 0);
        assertEq(uniforgeCollection.getApproved(0), blockedOperator);
    }

    function testFork_Approve_FilterONMinterApprovesNotBlockedOperator() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.getApproved(0), address(0));

        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.prank(minter);
        uniforgeCollection.approve(notBlockedOperator, 0);
        assertEq(uniforgeCollection.getApproved(0), notBlockedOperator);
    }

    function testFork_Approve_FilterONMinterAprovesBlockedOperator() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.getApproved(0), address(0));

        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.prank(minter);
        vm.expectRevert();
        uniforgeCollection.approve(blockedOperator, 0);
    }

    function testFork_TransferFrom_FilterOFF_EOATransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        
        uniforgeCollection.transferFrom(minter, holder, 0);

        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_TransferFrom_FilterOFF_NotBlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        vm.stopPrank();
        vm.startPrank(notBlockedOperator);
        uniforgeCollection.transferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_TransferFrom_FilterOFF_BlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        vm.stopPrank();
        vm.startPrank(blockedOperator);
        uniforgeCollection.transferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_TransferFrom_FilterON_EOATransfersToken() public {
        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        
        uniforgeCollection.transferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_TransferFrom_FilterON_NotBlockedTransfersToken() public {
         vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();
         vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        vm.stopPrank();
        vm.startPrank(notBlockedOperator);
        uniforgeCollection.transferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_TransferFrom_FilterON_BlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        vm.stopPrank();

        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.startPrank(blockedOperator);
        vm.expectRevert();
        uniforgeCollection.transferFrom(minter, holder, 0);
    }



 /* 4 - safeTransferFrom */

    function testFork_SafeTransferFrom_FilterOFF_EOATransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        
        uniforgeCollection.safeTransferFrom(minter, holder, 0);

        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom_FilterOFF_NotBlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        vm.stopPrank();
        vm.startPrank(notBlockedOperator);
        uniforgeCollection.safeTransferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom_FilterOFF_BlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        vm.stopPrank();
        vm.startPrank(blockedOperator);
        uniforgeCollection.safeTransferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom_FilterON_EOATransfersToken() public {
        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        
        uniforgeCollection.safeTransferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom_FilterON_NotBlockedTransfersToken() public {
         vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();
         vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        vm.stopPrank();
        vm.startPrank(notBlockedOperator);
        uniforgeCollection.safeTransferFrom(minter, holder, 0);
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom_FilterON_BlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        vm.stopPrank();

        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.startPrank(blockedOperator);
        vm.expectRevert();
        uniforgeCollection.safeTransferFrom(minter, holder, 0);
    }

    function testFork_SafeTransferFrom2_FilterOFF_EOATransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        
        uniforgeCollection.safeTransferFrom(minter, holder, 0, "");

        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom2_FilterOFF_NotBlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        vm.stopPrank();
        vm.startPrank(notBlockedOperator);
        uniforgeCollection.safeTransferFrom(minter, holder, 0, "");
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom2_FilterOFF_BlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        vm.stopPrank();
        vm.startPrank(blockedOperator);
        uniforgeCollection.safeTransferFrom(minter, holder, 0, "");
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom2_FilterON_EOATransfersToken() public {
        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        
        uniforgeCollection.safeTransferFrom(minter, holder, 0, "");
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom2_FilterON_NotBlockedTransfersToken() public {
         vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();
         vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(notBlockedOperator, true);
        vm.stopPrank();
        vm.startPrank(notBlockedOperator);
        uniforgeCollection.safeTransferFrom(minter, holder, 0, "");
        assertEq(uniforgeCollection.ownerOf(0), holder);
    }
    function testFork_SafeTransferFrom2_FilterON_BlockedTransfersToken() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        uniforgeCollection.setApprovalForAll(blockedOperator, true);
        vm.stopPrank();

        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();

        vm.startPrank(blockedOperator);
        vm.expectRevert();
        uniforgeCollection.safeTransferFrom(minter, holder, 0, "");
    }

    function testFork_SupportsInterface_IERC165True() public {
        assertEq(uniforgeCollection.supportsInterface(0x01ffc9a7), true);
    }

    function testFork_SupportsInterface_IERC721True() public {
        assertEq(uniforgeCollection.supportsInterface(0x80ac58cd), true);
    }

    function testFork_SupportsInterface_IERC721MetadataTrue() public {
        assertEq(uniforgeCollection.supportsInterface(0x5b5e139f), true);
    }

    function testFork_SupportsInterface_IERC2981True() public {
        assertEq(uniforgeCollection.supportsInterface(0x2a55205a), true);
    }

    function testFork_SupportsInterface_False() public {
        assertEq(uniforgeCollection.supportsInterface(0x00000000), false);
    }

    function testFork_BaseURI() public {
        assertEq(
            uniforgeCollection.baseURI(),
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/"
        );
    }

    function testFork_lockedBaseURI() public {
        assertEq(uniforgeCollection.lockedBaseURI(), false);
    }

    function testFork_TokenURI() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
        assertEq(
            uniforgeCollection.tokenURI(0),
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/0"
        );
    }

    function testFork_TokenURI_NotExistentTokenReturnsEmpty() public {
        vm.expectRevert();
        uniforgeCollection.tokenURI(5);
    }

    function testFork_MaxSupply() public {
        assertEq(uniforgeCollection.maxSupply(), 10000);
    }

    function testFork_MintFee() public {
        assertEq(uniforgeCollection.mintFee(), 1e16);
    }

    function testFork_MintLimit() public {
        assertEq(uniforgeCollection.mintLimit(), 10);
    }

    function testFork_SaleStart() public {
        assertEq(uniforgeCollection.saleStart(), 2);
    }

    function testFork_RoyaltyReceiver() public {
        assertEq(uniforgeCollection.royaltyReceiver(), owner);
    }

    function testFork_RoyaltyPercentage() public {
        assertEq(uniforgeCollection.royaltyPercentage(), 420);
    }

    function testFork_RoyaltyEnforced() public {
        assertEq(uniforgeCollection.royaltyEnforced(), false);
    }
}
