// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ClaimXFAToken {

    address immutable private token;
    address immutable private owner;
    address immutable private signer;
    uint256 immutable private tokenListingDate;
    mapping(address => uint256) private userClaimedTokens;     

    uint256 internal constant _MIN_COINS_FOR_VESTING = 23530 * 10 ** 18;    

    event onClaimBoughtTokens(address _user, uint256 _maxTokensAllowed);

    constructor(address _token, address _signer, uint256 _listingDate) {
        token = _token;
        signer = _signer;
        tokenListingDate = _listingDate;
        owner = msg.sender;
    }

    function claimTokens(bytes calldata _params, bytes calldata _messageLength, bytes calldata _signature) external {
        require(block.timestamp >= tokenListingDate, "TokenNoListedYet");

        address _signer = _decodeSignature(_params, _messageLength, _signature);
        require(_signer == signer, "BadSigner");

        (address _user, uint256 _boughtBalance) = abi.decode(_params, (address, uint256));
        require(_boughtBalance > 0, "NoBalance");
        uint256 maxTokensAllowed = 0;

        if ((block.timestamp >= tokenListingDate) && (block.timestamp < tokenListingDate + 90 days)) {
            if (_boughtBalance <= _MIN_COINS_FOR_VESTING) {
                maxTokensAllowed = _boughtBalance - userClaimedTokens[_user];
            } else {
                uint maxTokens = _boughtBalance * 25 / 100;
                if (userClaimedTokens[_user] < maxTokens) {
                    maxTokensAllowed = maxTokens - userClaimedTokens[_user];
                }
            }
        } else if ((block.timestamp >= tokenListingDate + 90 days) && (block.timestamp < tokenListingDate + 180 days)) {
            uint256 maxTokens = _boughtBalance * 50 / 100;
            if (userClaimedTokens[_user] < maxTokens) {
                maxTokensAllowed = maxTokens - userClaimedTokens[_user];
            }
        } else if ((block.timestamp >= tokenListingDate + 180 days) && (block.timestamp < tokenListingDate + 270 days)) {
            uint256 maxTokens = _boughtBalance * 75 / 100;
            if (userClaimedTokens[_user] < maxTokens) {
                maxTokensAllowed = maxTokens - userClaimedTokens[_user];
            }
        } else {
            uint256 maxTokens = _boughtBalance;
            if (userClaimedTokens[_user] < maxTokens) {
                maxTokensAllowed = maxTokens - userClaimedTokens[_user];
            }
        }

        require(maxTokensAllowed > 0, "NoTokensToWithdraw");

        userClaimedTokens[_user] += maxTokensAllowed;
        require(IERC20(token).transfer(_user, maxTokensAllowed));

        emit onClaimBoughtTokens(_user, maxTokensAllowed);
    }

    function emegercyWithdraw(address _token) external {
        require(msg.sender == owner, "OnlyOwner");

        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, tokenBalance);
    }

    function getClaimData(bytes calldata _params) external view returns(address _user, uint256 _boughtBalance, uint256 _claimed, uint256 _canWithdrawNow, uint256 _nextPeriod) {
        (_user, _boughtBalance) = abi.decode(_params, (address, uint256));
        _claimed = userClaimedTokens[_user];
        _nextPeriod = tokenListingDate;

        if ((block.timestamp >= tokenListingDate) && (block.timestamp < tokenListingDate + 90 days)) {
            if (_boughtBalance <= _MIN_COINS_FOR_VESTING) {
                _canWithdrawNow = _boughtBalance - userClaimedTokens[_user];
            } else {
                uint maxTokens = _boughtBalance * 25 / 100;
                if (userClaimedTokens[_user] < maxTokens) {
                    _canWithdrawNow = maxTokens - userClaimedTokens[_user];
                }
            }
            _nextPeriod = tokenListingDate + 90 days;
        } else if ((block.timestamp >= tokenListingDate + 90 days) && (block.timestamp < tokenListingDate + 180 days)) {
            uint256 maxTokens = _boughtBalance * 50 / 100;
            if (userClaimedTokens[_user] < maxTokens) {
                _canWithdrawNow = maxTokens - userClaimedTokens[_user];
            }
            _nextPeriod = tokenListingDate + 180 days;
        } else if ((block.timestamp >= tokenListingDate + 180 days) && (block.timestamp < tokenListingDate + 270 days)) {
            uint256 maxTokens = _boughtBalance * 75 / 100;
            if (userClaimedTokens[_user] < maxTokens) {
                _canWithdrawNow = maxTokens - userClaimedTokens[_user];
            }
            _nextPeriod = tokenListingDate + 270 days;
        } else {
            uint256 maxTokens = _boughtBalance;
            if (userClaimedTokens[_user] < maxTokens) {
                _canWithdrawNow = maxTokens - userClaimedTokens[_user];
            }
            _nextPeriod = 0;
        }
    }

    function getUserClaimedTokens(address _user) external view returns(uint256) {
        return userClaimedTokens[_user];
    }

    function _decodeSignature(bytes memory _message, bytes memory _messageLength, bytes memory _signature) internal pure returns (address) {
        if (_signature.length != 65) return (address(0));

        bytes32 messageHash = keccak256(abi.encodePacked(hex"19457468657265756d205369676e6564204d6573736167653a0a", _messageLength, _message));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);

        if (v != 27 && v != 28) return address(0);
        
        return ecrecover(messageHash, v, r, s);
    }
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