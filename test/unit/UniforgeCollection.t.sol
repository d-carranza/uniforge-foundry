// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import "src/UniforgeCollection.sol";

contract UniforgeCollectionTest is Test {
    UniforgeCollection public uniforgeCollection;

    address deployer = makeAddr("deployer");
    address owner = makeAddr("owner");
    address minter = makeAddr("minter");
    address holder = makeAddr("holder");

    event MintFeeUpdated(uint256 indexed mintFee);
    event BaseURIUpdated(string indexed baseURI);
    event RoyalityRecipientUpdated(address indexed royaltyAddress);
    event RoyalitiesEnforced(bool indexed enabled);

    function setUp() public {
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

    function test_Constructor_DeployerBecomesOwner() public {
        assertEq(uniforgeCollection.owner(), owner);
    }

    function test_Constructor_BaseURIStored() public {
        assertEq(
            uniforgeCollection.baseURI(),
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/"
        );
    }

    function test_Constructor_MintFeeStored() public {
        assertEq(uniforgeCollection.mintFee(), 1e16);
    }

    function test_Constructor_MaxMintAmountStored() public {
        assertEq(uniforgeCollection.mintLimit(), 10);
    }

    function test_Constructor_MaxSupplyStored() public {
        assertEq(uniforgeCollection.maxSupply(), 10000);
    }

    function test_Constructor_SaleStartStored() public {
        assertEq(uniforgeCollection.saleStart(), 2);
    }

    function test_MintNft_ZeroMintAmountReverts() public {
        vm.prank(minter);
        vm.expectRevert();
        uniforgeCollection.mintNft(0);
    }

    function test_MintNft_LessMintAmount() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function test_MintNft_EqualMintAmount() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 2 * 1e16}(2);
        assertEq(uniforgeCollection.totalSupply(), 2);
    }

    function test_MintNft_MoreMintAmountReverts() public {
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__InvalidMintAmount.selector);
        uniforgeCollection.mintNft{value: 11 * 1e16}(11);
    }

    function test_MintNft_ClosedSaleReverts() public {
        vm.warp(1);
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__SaleIsNotOpen.selector);
        uniforgeCollection.mintNft{value: 1e16}(1);
    }

    function test_MintNft_ZeroEthReverts() public {
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__NeedMoreETHSent.selector);
        uniforgeCollection.mintNft(1);
    }

    function test_MintNft_ZeroEthSucceedsWhenMintFeeZero() public {
        vm.prank(owner);
        uniforgeCollection.setMintFee(0);
        vm.prank(minter);
        uniforgeCollection.mintNft(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function test_MintNft_LessEthReverts() public {
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__NeedMoreETHSent.selector);
        uniforgeCollection.mintNft{value: 1e15}(1);
    }

    function test_MintNft_EqualEth() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function test_MintNft_MoreEth() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e17}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function test_MintNFT_RevertsWhenMintMoreThanSupply() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(msg.sender, 10000);
        vm.prank(minter);
        vm.expectRevert(UniforgeCollection__MaxSupplyExceeded.selector);
        uniforgeCollection.mintNft{value: 1e17}(1);
    }

    function test_CreatorMint_OwnerMintsSelf() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(msg.sender, 1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function test_CreatorMint_OwnerMintsToOther() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(minter, 1);
        assertEq(uniforgeCollection.totalSupply(), 1);
    }

    function test_CreatorMint_OwnerMintsMore() public {
        vm.prank(owner);
        uniforgeCollection.creatorMint(msg.sender, 5);
        assertEq(uniforgeCollection.totalSupply(), 5);
    }

    function test_CreatorMint_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.creatorMint(minter, 5);
    }

    function test_CreatorMint_RevertsWhenMintMoreThanSupply() public {
        vm.startPrank(owner);
        vm.expectRevert(UniforgeCollection__MaxSupplyExceeded.selector);
        uniforgeCollection.creatorMint(msg.sender, 10001);
    }

    function test_Withdraw_OwnerWithdrawSuccessfully() public {
        uint256 initialBalance = owner.balance;
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        vm.prank(owner);
        uniforgeCollection.withdraw();
        assertEq(owner.balance, initialBalance + 1e16);
    }

    function test_Withdraw_NotOwnerReverts() public {
        vm.startPrank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.withdraw();
    }

    function test_Withdraw_FailedCallReverts() public {
        vm.prank(owner);
        uniforgeCollection.transferOwnership(address(this));
        vm.prank(address(this));
        vm.expectRevert(UniforgeCollection__TransferFailed.selector);
        uniforgeCollection.withdraw();
    }

    function test_SetMintFee_OwnerUpdatesFee() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit MintFeeUpdated(1e18);
        uniforgeCollection.setMintFee(1e18);
        assertEq(uniforgeCollection.mintFee(), 1e18);
    }

    function test_SetMintFee_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.setMintFee(1e18);
    }

    function test_SetBaseURI_OwnerUpdatesBaseURI() public {
        vm.prank(owner);
        uniforgeCollection.setBaseURI("hello");
        assertEq(uniforgeCollection.baseURI(), "hello");
    }

    function test_SetBaseURI_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.setBaseURI("hello");
    }

    function test_SetBaseURI_LockedBaseURIReverts() public {
        vm.startPrank(owner);
        uniforgeCollection.lockBaseURI();
        vm.expectRevert(UniforgeCollection__LockedBaseURI.selector);
        uniforgeCollection.setBaseURI("hello");
    }

    function test_LockBaseURI_OwnerLocksBaseURI() public {
        vm.prank(owner);
        uniforgeCollection.lockBaseURI();
        assertEq(uniforgeCollection.lockedBaseURI(), true);
    }

    function test_LockBaseURI_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.lockBaseURI();
    }

    // function test_SetMintLomit_OwnerUpdatesAmount() public {
    //     vm.prank(owner);
    //     uniforgeCollection.setMintLimit(20);
    //     assertEq(uniforgeCollection.mintLimit(), 20);
    // }

    // function test_SetMintLimit_NotOwnerReverts() public {
    //     vm.prank(minter);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     uniforgeCollection.setMintLimit(20);
    // }

    // function test_SetSaleStart_OwnerUpdatesSaleStart() public {
    //     vm.prank(owner);
    //     uniforgeCollection.setSaleStart(170000000);
    //     assertEq(uniforgeCollection.saleStart(), 170000000);
    // }

    // function test_SetSaleStart_NotOwnerReverts() public {
    //     vm.prank(minter);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     uniforgeCollection.setSaleStart(170000000);
    // }


    function test_SetDefaultRoyalty_OwnerUpdatesDefaultRoyalty() public {
        vm.startPrank(owner);
        uniforgeCollection.creatorMint(minter, 10);
        uniforgeCollection.setDefaultRoyalty(minter, 690);
        (address reciever, uint256 fee) = uniforgeCollection.royaltyInfo(0, 1000);
        assertEq(reciever, minter); 
        assertEq(fee, 69); 
    }

    function test_SetDefaultRoyalty_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.setDefaultRoyalty(minter, 690);
    }

    // function test_DeleteDefaultRoyalty_OwnerDeletesDefaultRoyalty() public {
    //     vm.startPrank(owner);
    //     uniforgeCollection.creatorMint(minter, 10);
    //     uniforgeCollection.deleteDefaultRoyalty();
    //      (address reciever, uint256 fee) = uniforgeCollection.royaltyInfo(0, 1000);
    //     assertEq(reciever, address(0)); 
    //     assertEq(fee, 0); 
    // }

    // function test_DeleteDefaultRoyalty_NotOwnerReverts() public {
    //     vm.prank(minter);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     uniforgeCollection.setDefaultRoyalty(minter, 690);
    // }

     function test_ToggleRoyaltyEnforcement_OwnerTogglesFilter() public {
        vm.prank(owner);
        uniforgeCollection.toggleRoyaltyEnforcement();
        assertEq(uniforgeCollection.royaltyEnforced(), true);
    }

     function test_ToggleRoyaltyEnforcement_NotOwnerReverts() public {
        vm.prank(minter);
        vm.expectRevert("Ownable: caller is not the owner");
        uniforgeCollection.toggleRoyaltyEnforcement();
    }

/**
 * @notice Commented functions tested in the fork tests:
 *
 * setApprovalForAll(address operator, bool approved)
 *
 * approve(address operator, uint256 tokenId)
 *
 * transferFrom(address from, address to, uint256 tokenId)
 *
 * safeTransferFrom(address from, address to, uint256 tokenId)
 *
 * safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
 */

    function test_SupportsInterface_IERC165True() public {
        assertEq(uniforgeCollection.supportsInterface(0x01ffc9a7), true);
    }

    function test_SupportsInterface_IERC721True() public {
        assertEq(uniforgeCollection.supportsInterface(0x80ac58cd), true);
    }

    function test_SupportsInterface_IERC721MetadataTrue() public {
        assertEq(uniforgeCollection.supportsInterface(0x5b5e139f), true);
    }

    function test_SupportsInterface_IERC2981True() public {
        assertEq(uniforgeCollection.supportsInterface(0x2a55205a), true);
    }

    function test_SupportsInterface_False() public {
        assertEq(uniforgeCollection.supportsInterface(0x00000000), false);
    }

    function test_BaseURI() public {
        assertEq(
            uniforgeCollection.baseURI(),
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/"
        );
    }

    function test_lockedBaseURI() public {
        assertEq(uniforgeCollection.lockedBaseURI(), false);
    }

    function test_TokenURI() public {
        vm.prank(minter);
        uniforgeCollection.mintNft{value: 1e16}(1);
        assertEq(uniforgeCollection.totalSupply(), 1);
        assertEq(
            uniforgeCollection.tokenURI(0),
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/0"
        );
    }

    function test_TokenURI_NotExistentTokenReturnsEmpty() public {
        vm.expectRevert();
        uniforgeCollection.tokenURI(5);
    }

    function test_MaxSupply() public {
        assertEq(uniforgeCollection.maxSupply(), 10000);
    }

    function test_MintFee() public {
        assertEq(uniforgeCollection.mintFee(), 1e16);
    }

    function test_MintLimit() public {
        assertEq(uniforgeCollection.mintLimit(), 10);
    }

    function test_SaleStart() public {
        assertEq(uniforgeCollection.saleStart(), 2);
    }

    function test_RoyaltyReceiver() public {
        assertEq(uniforgeCollection.royaltyReceiver(), owner);
    }

    function test_RoyaltyPercentage() public {
        assertEq(uniforgeCollection.royaltyPercentage(), 420);
    }

    function test_RoyaltyEnforced() public {
        assertEq(uniforgeCollection.royaltyEnforced(), false);
    }
}
