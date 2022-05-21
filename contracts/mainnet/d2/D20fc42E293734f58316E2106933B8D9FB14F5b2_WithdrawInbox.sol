// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "../safeguard/Ownable.sol";

/**
 * @title A contract to initiate withdrawal requests for contracts tha provide liquidity to {Bridge}.
 */
contract WithdrawInbox is Ownable {
    // min allowed max slippage uint32 value is slippage * 1M, eg. 0.5% -> 5000
    uint32 public minimalMaxSlippage;
    // the period of time during which a withdrawal request is intended to be valid
    uint256 public validityPeriod;

    // contract LP withdrawal request
    event WithdrawalRequest(
        uint64 seqNum,
        address sender,
        address receiver,
        uint64 toChain,
        uint64[] fromChains,
        address[] tokens,
        uint32[] ratios,
        uint32[] slippages,
        uint256 deadline
    );

    constructor() {
        // default validityPeriod is 2 hours
        validityPeriod = 7200;
    }

    /**
     * @notice Withdraw liquidity from the pool-based bridge.
     * NOTE: Each of your withdrawal request should have different _wdSeq.
     * NOTE: Tokens to withdraw within one withdrawal request should have the same symbol.
     * @param _wdSeq The unique sequence number to identify this withdrawal request.
     * @param _receiver The receiver address on _toChain.
     * @param _toChain The chain Id to receive the withdrawn tokens.
     * @param _fromChains The chain Ids to withdraw tokens.
     * @param _tokens The token to withdraw on each fromChain.
     * @param _ratios The withdrawal ratios of each token.
     * @param _slippages The max slippages of each token for cross-chain withdraw.
     */
    function withdraw(
        uint64 _wdSeq,
        address _receiver,
        uint64 _toChain,
        uint64[] calldata _fromChains,
        address[] calldata _tokens,
        uint32[] calldata _ratios,
        uint32[] calldata _slippages
    ) external {
        require(_fromChains.length > 0, "empty withdrawal request");
        require(
            _tokens.length == _fromChains.length &&
                _ratios.length == _fromChains.length &&
                _slippages.length == _fromChains.length,
            "length mismatch"
        );
        for (uint256 i = 0; i < _ratios.length; i++) {
            require(_ratios[i] > 0 && _ratios[i] <= 1e8, "invalid ratio");
            require(_slippages[i] >= minimalMaxSlippage, "slippage too small");
        }
        uint256 _deadline = block.timestamp + validityPeriod;
        emit WithdrawalRequest(
            _wdSeq,
            msg.sender,
            _receiver,
            _toChain,
            _fromChains,
            _tokens,
            _ratios,
            _slippages,
            _deadline
        );
    }

    // ------------------------Admin operations--------------------------

    function setMinimalMaxSlippage(uint32 _minimalMaxSlippage) external onlyOwner {
        minimalMaxSlippage = _minimalMaxSlippage;
    }

    function setValidityPeriod(uint256 _validityPeriod) external onlyOwner {
        validityPeriod = _validityPeriod;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * This adds a normal func that setOwner if _owner is address(0). So we can't allow
 * renounceOwnership. So we can support Proxy based upgradable contract
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Only to be called by inherit contracts, in their init func called by Proxy
     * we require _owner == address(0), which is only possible when it's a delegateCall
     * because constructor sets _owner in contract state.
     */
    function initOwner() internal {
        require(_owner == address(0), "owner already set");
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}