// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "src/UniforgeCollection.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract UniforgeCollectionFuzzTest is Test {
    using Strings for uint256;
    UniforgeCollection public uniforgeCollection;

    address deployer = makeAddr("deployer");
    address owner = makeAddr("owner");
    address minter = makeAddr("minter");

    event MintFeeUpdated(uint256 indexed mintFee);
    event BaseURIUpdated(string indexed baseURI);
    event RoyaltyEnforced(bool indexed enabled);
    event RoyaltyUpdated(address indexed royaltyReceiver, uint96 indexed royaltyPercentage);

    function setUp() public {
        vm.prank(deployer);
        uniforgeCollection = new UniforgeCollection(
            owner,
            "Dappenics",
            "DAPE",
            "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/",
            1e16,
            2,
            10000,
            1,
            100,
            false
        );
        deal(minter, 1e20);
    }

    function testFuzz_MintNft(uint256 _mintAmount) public {
        vm.assume(_mintAmount != 0);
        vm.assume(_mintAmount <= uniforgeCollection.mintLimit());
        vm.prank(minter);
        uniforgeCollection.mintNft{value: _mintAmount * 1e16}(_mintAmount);
        assertEq(uniforgeCollection.totalSupply(), _mintAmount);
    }

    function testFuzz_FreeMintForAddress_Owner(
        address _receiver,
        uint256 _mintAmount
    ) public {
        vm.assume(_mintAmount != 0);
        vm.assume(_mintAmount <= uniforgeCollection.maxSupply());
        vm.prank(owner);
        uniforgeCollection.creatorMint(_receiver, _mintAmount);
        assertEq(uniforgeCollection.totalSupply(), _mintAmount);
    }

    function testFuzz_SetBaseURI_Owner(string memory _baseURI) public {
        vm.prank(owner);
        uniforgeCollection.setBaseURI(_baseURI);
        assertEq(uniforgeCollection.baseURI(), _baseURI);
    }

    function testFuzz_SetMintFee_Owner(uint256 _mintFee) public {
        vm.prank(owner);
        uniforgeCollection.setMintFee(_mintFee);
        assertEq(uniforgeCollection.mintFee(), _mintFee);
    }

//    function test_SetMintLimit_Owner(uint256 _mintMaxAmount) public {
//         vm.prank(owner);
//         uniforgeCollection.setMintLimit(_mintMaxAmount);
//         assertEq(uniforgeCollection.mintLimit(), _mintMaxAmount);
//     }

//     function test_SetSaleStart_Owner(uint256 _saleStart) public {
//         vm.prank(owner);
//         uniforgeCollection.setSaleStart(_saleStart);
//         assertEq(uniforgeCollection.saleStart(), _saleStart);
//     }

    function testFuzz_tokenURI(uint256 _tokenId) public {
        deal(owner, 1e18);
        vm.prank(owner);
        uniforgeCollection.creatorMint(minter, 100);
        assertEq(uniforgeCollection.totalSupply(), 100);
        vm.assume(_tokenId < uniforgeCollection.totalSupply());
        assertEq(
            uniforgeCollection.tokenURI(_tokenId),
            string(
                abi.encodePacked(
                    "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/",
                    _tokenId.toString()
                )
            )
        );
    }
}
