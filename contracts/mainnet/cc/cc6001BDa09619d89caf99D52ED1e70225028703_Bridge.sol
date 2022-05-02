// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IToken.sol";

contract Bridge {
    address public validator;
    uint256 public fee = 50;
    uint256 public feeDominator = 10000;
    uint256 private currentNonce = 0;
    address payable public feeRecevier;
    mapping(bytes32 => bool) public processedSwap;
    mapping(bytes32 => bool) public processedRedeem;
    mapping(string => address) public tickerToToken;
    mapping(uint256 => bool) public activeChainIds;

    event SwapInitialized(address indexed from, address indexed to, uint256 amount, string ticker, uint256 chainTo, uint256 chainFrom, uint256 nonce);

    event Redeemed(address indexed from, address indexed to, uint256 amount, string ticker, uint256 chainTo, uint256 chainFrom, uint256 nonce);
    event WithdrawalFee(address indexed account, uint256 amount);

    constructor(address payable _feeRecevier) {
        validator = msg.sender;
        feeRecevier = _feeRecevier;
    }

    function swap(
        address to,
        uint256 amount,
        string memory ticker,
        uint256 chainTo,
        uint256 chainFrom
    ) external payable {
        uint256 _fee = calculateFee();
        require(msg.value >= _fee, "Swap fee is not fulfilled");
        uint256 nonce = currentNonce;
        currentNonce++;

        require(processedSwap[keccak256(abi.encodePacked(msg.sender, to, amount, chainFrom, chainTo, ticker, nonce))] == false, "swap already processed");
        bytes32 hash_ = keccak256(abi.encodePacked(msg.sender, to, amount, chainFrom, chainTo, ticker, nonce));

        processedSwap[hash_] = true;
        address token = tickerToToken[ticker];
        IToken(token).burn(msg.sender, amount);
        emit SwapInitialized(msg.sender, to, amount, ticker, chainTo, chainFrom, nonce);
    }

    function redeem(
        address from,
        address to,
        uint256 amount,
        string memory ticker,
        uint256 chainFrom,
        uint256 chainTo,
        uint256 nonce,
        bytes calldata signature
    ) external {
        bytes32 hash_ = keccak256(abi.encodePacked(from, to, amount, ticker, chainFrom, chainTo, nonce));
        require(processedRedeem[hash_] == false, "Redeem already processed");
        processedRedeem[hash_] = true;

        require(getChainID() == chainTo, "invalid chainTo");
        require(recoverSigner(hashMessage(hash_), signature) == validator, "invalid sig");

        address token = tickerToToken[ticker];
        IToken(token).mint(to, amount);

        emit Redeemed(from, to, amount, ticker, chainTo, chainFrom, nonce);
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param message bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function hashMessage(bytes32 message) private pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function isValidator() internal view returns (bool) {
        return (validator == msg.sender);
    }

    modifier onlyValidator() {
        require(isValidator(), "DENIED : Not Validator");
        _;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function updateChainById(uint256 chainId, bool isActive) external onlyValidator {
        activeChainIds[chainId] = isActive;
    }

    function includeToken(string memory ticker, address addr) external {
        require(msg.sender == validator, "only validator");
        tickerToToken[ticker] = addr;
    }

    function excludeToken(string memory ticker) external onlyValidator {
        delete tickerToToken[ticker];
    }

    function updateValidator(address _validator) external onlyValidator {
        validator = _validator;
    }

    function updateFeeRecevier(address payable _feeRecevier) external onlyValidator {
        feeRecevier = _feeRecevier;
    }

    function updateFee(uint256 _fee) external onlyValidator {
        fee = _fee;
    }

    function calculateFee() public view returns (uint256) {
        return (fee * (1e18)) / feeDominator;
    }

    function withdrawFee() external onlyValidator {
        uint256 amount = (address(this)).balance;
        feeRecevier.transfer(amount);
        emit WithdrawalFee(feeRecevier, amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IToken {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}