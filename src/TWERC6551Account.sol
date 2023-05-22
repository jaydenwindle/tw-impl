// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "thirdweb-contracts/eip/interface/IERC721.sol";
import "./lib/TWAccount.sol";

import "erc6551/lib/ERC6551AccountLib.sol";
import "erc6551/interfaces/IERC6551Account.sol";

/**
 * @dev An ERC-6551 account implementation using Thirdweb's ERC-4337 Account contract
 * @author Jayden Windle (@jaydenwindle)
 */
contract TWERC6551Account is IERC6551Account, TWAccount {
    modifier onlyAdminOrEntrypoint() override {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner(),
            "Account: not admin or EntryPoint."
        );
        _;
    }

    receive() external payable override(IERC6551Account, TWAccount) {}

    constructor(IEntryPoint _entrypoint, address _factory)
        TWAccount(_entrypoint, _factory)
    {}

    /*///////////////////////////////////////////////////////////////
                            ERC6551 Methods
    //////////////////////////////////////////////////////////////*/

    function owner() public view returns (address) {
        (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        ) = ERC6551AccountLib.token();

        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function token()
        external
        view
        returns (
            uint256,
            address,
            uint256
        )
    {
        return ERC6551AccountLib.token();
    }

    function nonce() external view returns (uint256) {
        return getNonce();
    }

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyAdminOrEntrypoint returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              Overrides
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether a signer is authorized to perform transactions using the wallet.
    function isValidSigner(address _signer)
        public
        view
        override
        returns (bool)
    {
        return _signer == owner();
    }

    /// @notice Withdraw funds for this account from Entrypoint.
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount)
        public
        override
    {
        require(
            msg.sender == owner(),
            "TWERC6551Account: Only owner can withdraw deposit"
        );
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /// @notice Registers a signer in the factory.
    function _setupRole(bytes32 role, address account) internal override {
        // disable role based access control
    }

    /// @notice Un-registers a signer in the factory.
    function _revokeRole(bytes32 role, address account) internal override {
        // disable role based access control
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner();
    }
}
