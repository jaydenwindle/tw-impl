// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "thirdweb-contracts/smart-wallet/utils/EntryPoint.sol";

import "erc6551/ERC6551Registry.sol";
import "erc6551/interfaces/IERC6551Account.sol";

import "../src/TWERC6551Account.sol";
import "./mocks/MockERC721.sol";

contract TWERC6551AccountTest is Test {
    using ECDSA for bytes32;

    TWERC6551Account public implementation;
    ERC6551Registry public registry;
    IEntryPoint public entryPoint;

    MockERC721 public tokenCollection;

    function setUp() public {
        entryPoint = new EntryPoint();
        implementation = new TWERC6551Account(entryPoint, address(0));
        registry = new ERC6551Registry();

        tokenCollection = new MockERC721();
    }

    function test4337CallCreateAccount() public {
        uint256 tokenId = 1;
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        tokenCollection.mint(user1, tokenId);
        assertEq(tokenCollection.ownerOf(tokenId), user1);

        address accountAddress = registry.account(
            address(implementation),
            block.chainid,
            address(tokenCollection),
            tokenId,
            0
        );

        bytes memory initCode = abi.encodePacked(
            address(registry),
            abi.encodeWithSignature(
                "createAccount(address,uint256,address,uint256,uint256,bytes)",
                address(implementation),
                block.chainid,
                address(tokenCollection),
                tokenId,
                0,
                ""
            )
        );

        bytes memory callData = abi.encodeWithSignature(
            "executeCall(address,uint256,bytes)",
            user2,
            0.1 ether,
            ""
        );

        UserOperation memory op = UserOperation({
            sender: accountAddress,
            nonce: 0,
            initCode: initCode,
            callData: callData,
            callGasLimit: 1000000,
            verificationGasLimit: 1000000,
            preVerificationGas: 1000000,
            maxFeePerGas: block.basefee + 10,
            maxPriorityFeePerGas: 10,
            paymasterAndData: "",
            signature: ""
        });

        bytes32 opHash = entryPoint.getUserOpHash(op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            1,
            opHash.toEthSignedMessageHash()
        );

        bytes memory signature = abi.encodePacked(r, s, v);
        op.signature = signature;

        vm.deal(accountAddress, 1 ether);

        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;

        assertEq(entryPoint.getNonce(accountAddress, 0), 0);
        entryPoint.handleOps(ops, payable(user1));
        assertEq(entryPoint.getNonce(accountAddress, 0), 1);

        assertEq(user2.balance, 0.1 ether);
        assertTrue(accountAddress.balance < 0.9 ether);
    }
}
