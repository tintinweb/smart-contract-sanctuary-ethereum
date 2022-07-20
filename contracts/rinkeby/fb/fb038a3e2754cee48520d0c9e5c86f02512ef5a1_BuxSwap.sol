// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IERC20.sol";

error Paused();
error NonceAlreadyUsed();
error InvalidSignature();
error NotEnoughInPool();
error ClaimExpired();

contract BuxSwap is Ownable {
    using ECDSA for bytes32;

    event Claimed(address account, uint256 amount);
    event Deposited(address account, address token, uint256 amount);

    address public claimSigner; // ECDSA signer
    mapping(uint256 => bool) private usedNonces;
    bool public paused = false;

    constructor(address signer) {
        claimSigner = signer;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setSigner(address signer) external onlyOwner {
        claimSigner = signer;
    }

    function balanceOf(address token)
        public
        view
        virtual
        returns (uint256 balance)
    {
        return IERC20(token).balanceOf(address(this));
    }

    function _transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).transferFrom(from, to, amount);
    }

    ////////////////
    /// Claiming ///
    ////////////////

    /// @dev claim $GoldBux
    function claim(
        address token,
        uint256 amount,
        uint256 nonce,
        uint256 expires,
        bytes memory signature
    ) external {
        if (paused) revert Paused();
        if (usedNonces[nonce]) revert NonceAlreadyUsed();
        if (amount > balanceOf(token)) revert NotEnoughInPool();
        if (block.timestamp > expires) revert ClaimExpired();

        // verify signature
        bytes32 msgHash = keccak256(
            abi.encodePacked(_msgSender(), token, nonce, expires, amount)
        );
        if (!isValidSignature(msgHash, signature)) revert InvalidSignature();
        usedNonces[nonce] = true;

        // approve & transfer token to user
        IERC20(token).approve(address(this), amount);
        _transfer(token, address(this), _msgSender(), amount);
        emit Claimed(_msgSender(), amount);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return signedHash.recover(signature) == claimSigner;
    }

    // @dev desposit amount of token to address
    function deposit(address token, uint256 amount) external {
        if (paused) revert Paused();
        _transfer(token, _msgSender(), address(this), amount);
        emit Deposited(_msgSender(), token, amount);
    }

    ////////////////
    /// Withdraw ///
    ////////////////

    // @dev withdraw any currency that gets mistakenly sent to this address
    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        // TODO how to withdraw ETH?
        // TODO how to withdraw all?
        _transfer(token, address(this), to, amount);
    }
}