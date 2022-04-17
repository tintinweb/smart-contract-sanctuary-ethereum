/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2021 Woonkly OU

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED BY WOONKLY OU "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/


pragma solidity 0.6.12;


contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity 0.6.12;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}



interface IBEP20MintableBurnable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}




contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}



contract Cross is
    Context,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    using SafeMath for uint256;

    struct Register {
        uint256 pending; // pending amount to cross 1
        uint256 confirmed; // confirmed amount crossed
        uint256 nonce1;
        uint256 nonce2;
    }

    mapping(address => Register) internal _registered; // get registered by address
    IBEP20MintableBurnable internal _cross; // CROSS erc20 IBEP20MintableBurnable token
    address internal _feeCollector; // fee collecting account
    uint32 internal _fee; // fee % charge 0.01 % min fraction allowed
    uint32 internal _baseFee; // base fee for 0.01 % min allowed calculation fraction
    address internal _validator; // validator wallet account



    uint256 _min_definition = 1000000000000000; // define minumun divisible transaccion size

    uint256 _limitAmount = 10000 ether; //User mint amount should be limited

    bool internal _isCrossOrigin; // used to identify current blockchain is the cross token origin

    event FeeChanged(uint32 oldFee, uint32 newFee);
    event BaseFeeChanged(uint32 oldbFee, uint32 newbFee);
    event FeeCollectorChanged(address oldOp, address newOp);
    event CROSSChanged(address oldf, address newf);
    event RequestedToCROSS(address indexed account, uint256 amount);
    event CrossReceived(address indexed account, uint256 amount);
    event LimitAmountChanged(uint256 olda, uint256 newa);




    /**
     * @dev
     *
     *
     * Create the main contract:
     *
     * Parameters:
     *         uint32 feeOperation: fee charged for each transaction
     *         address cross: ERC20 CROSS token address
     *         address custodian: custodian cross token address
     *         address operations: Tax Collector
     *         bool isTokenOrigin: used to identify current blockchain is the cross token origin
     *
     */
    constructor(
        uint32 fee,
        address cross,
        address feeCollector,
        bool isTokenOrigin
    ) public {
        _fee = fee;
        _cross = IBEP20MintableBurnable(cross);
        _feeCollector = feeCollector;
        _validator =  owner();
        _isCrossOrigin = isTokenOrigin;
        _baseFee = 10000; // for 0.01 % unit
    }


    function calcFeesAndNet(
        uint256 amount,
        uint32 fee,
        uint32 baseFee
    ) public pure returns (uint256 _net, uint256 __fee) {
        if (baseFee == 0) {
            __fee = 0;
            _net = amount;
        } else {
            __fee = amount.mul(fee).div(baseFee);
            _net = amount - __fee;
        }
    }


    /// All functions below this are just taken from the chapter
    /// 'creating and verifying signatures' chapter.

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }





    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        if (v < 27) v += 27;

        return ecrecover(message, v, r, s);
    }


    /**
     * @dev get minimal definition factor allowed to cross
     *
     *
     */
    function getMinDefinitionFactor() public view returns (uint256) {
        return _min_definition;
    }

    /**
     * @dev get fee charge
     *
     *
     */
    function getFee() public view returns (uint32) {
        return _fee;
    }

    /**
     * @dev change fee charge transaction value
     *
     * Emit {FeeOperationChanged} evt
     *
     * Requirements:
     *      only Is InOwners require &&   newFee <= 1000000  && newFee <= _baseFee
     */
    function setFee(uint32 newFee) external onlyOwner returns (bool) {
        require((newFee <= 1000000), "1");
        require((newFee <= _baseFee), "2");

        uint32 old = _fee;
        _fee = newFee;
        emit FeeChanged(old, _fee);
        return true;
    }


    /**
     * @dev get base fee needed for tax calculation
     *
     *
     */
    function getBaseFee() public view returns (uint32) {
        return _baseFee;
    }

    /**
     * @dev change base fee needed for tax calculation
     *
     * Emit {BaseFeeChanged} evt
     *
     * Requirements:
     *      only Is InOwners require &&   newbFee <= 1000000 && newFee >= _fee
     */
    function setBaseFee(uint32 newbFee) external onlyOwner returns (bool) {
        require((newbFee <= 1000000), "1");
        require((newbFee >= _fee), "2");
        uint32 old = _baseFee;
        _baseFee = newbFee;
        emit BaseFeeChanged(old, _baseFee);
        return true;
    }




    /**
     * @dev get fee Collector wallet address
     *
     *
     */
    function getFeeCollector() public view returns (address) {
        return _feeCollector;
    }

    /**
     * @dev change  fee Collector wallet address
     *
     * Emit {FeeCollectorChanged} evt
     *
     * Requirements:
     *      only Is InOwners require
     */
    function setFeeCollector(address newOp)
        external
        onlyOwner
        returns (bool)
    {
        address old = _feeCollector;
        _feeCollector = newOp;
        emit FeeCollectorChanged(old, _feeCollector);
        return true;
    }


    /**
     * @dev change  validator wallet address
     *
     *
     * Requirements:
     *      only IsOwner require
     */
    function setValidator(address newVal)
        external
        onlyOwner
        returns (bool)
    {
        _validator = newVal;
        return true;
    }



    /**
     * @dev change max amount permited restriction
     *
     * Emit {LimitAmountChanged} evt
     *
     * Requirements:
     *      only Is InOwners
     */
    function setMaxAmountLimit(uint256 newLimit)
        external
        onlyOwner
        returns (bool)
    {
        uint256 old = _limitAmount;
        _limitAmount = newLimit;
        emit LimitAmountChanged(old, newLimit);
        return true;
    }


    /**
     * @dev get limit max amount per cross
     *
     *
     */
    function getLimitAmount() public view returns (uint256) {
        return _limitAmount;
    }



    /**
     * @dev reset wallet counters
     *
     *
     * Requirements:
     *      only Is InOwners
     */
    function resetWallet(address account) external onlyOwner {
        _registered[account].pending = 0;
        _registered[account].confirmed = 0;
        _registered[account].nonce1 = 0;
        _registered[account].nonce2 = 0;
    }

    /**
     * @dev zip amount to min definition
     *
     *
     */
    function toMin(uint256 amount) public view returns (uint256) {
        if (_min_definition == 0) return amount;
        return amount.div(_min_definition);
    }

    /**
     * @dev unzip amount from min definition to uint256
     *
     *
     */
    function toMax(uint256 amount) public view returns (uint256) {
        if (_min_definition == 0) return amount;
        return amount.mul(_min_definition);
    }


    function unpause() public onlyOwner whenPaused{
        _unpause();
    }


    function pause() public onlyOwner whenNotPaused{
        _pause();
    }


    /**
     * @dev First step to transfer CROSS  between blockchains
     *      burn CROSS amount
     *
     *
     * Requirements:
     *   amount > 0
     *   nonReentrant &&  not whenNotPaused &
     *   amount <= (_cross.balanceOf )
     *
     * Emit {RequestedToCROSS} evt
     *
     */
    function requestToCROSS(uint256 amount)
        external
        whenNotPaused
        nonReentrant
    {

        // el minimo debe ser > 0
        require(
            toMin(amount) > 0,
            "Cross: amount under the minimum allowed"
        );

        //User amount should be limited
        require(amount <= _limitAmount, "Cross: amount exceeds limit");

        //debe tener saldo suficiente
        
        require(
            _cross.balanceOf(_msgSender()) >= amount,
            "Cross: insufficient balance"
        );
        


        if (_isCrossOrigin) {
            //MsgSender has allowance to transfer amount to custodian contract
            require(
                _cross.allowance(_msgSender(), address(this)) >= amount,
                "Cross: insufficient allowance"
            );
        }


        // se agrega a pendiente de este lado
        _registered[_msgSender()].pending = _registered[_msgSender()]
            .pending
            .add(toMin(amount));

        // cambia el nro serie local 
        _registered[_msgSender()].nonce1 =_registered[_msgSender()].nonce1.add(1);


        if (_isCrossOrigin) {

            TransferHelper.safeTransferFrom(
                address(_cross),
                _msgSender(),
                address(this),
                amount
            );

        } else {
            _cross.burn(_msgSender(), amount);
        }

        emit RequestedToCROSS(_msgSender(), amount);
    }



    function _getHash2(address account,uint256 amount,uint256 nonce) private pure returns(bytes32) {
        
        return keccak256(abi.encodePacked(account,amount,nonce));
    }       


    function _getHash(address account,uint256 amount,uint256 nonce) private pure returns(bytes32) {
        
        bytes32 hash = _getHash2( account, amount, nonce) ;
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    }       


    /**
     * @dev get current user info + hash
     *
     *
     */
    function getCrossData(address account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bytes32
        )
    {
        return (
            _registered[account].pending,
            _registered[account].confirmed,
            _registered[account].nonce1,
            _getHash2( account, _registered[account].pending, _registered[account].nonce1)

        );
    }



    /**
     * @dev receives the pending tokens to be transferred to destination blockchain
     *
     *
     * Requirements:
     *   not isPaused
     *   nonReentrant
     *
     * Emit {CrossReceived} evt
     *
     */
    function crossReceive(
        uint256 pending,
        uint256 n1,
        bytes32 hash,
        bytes memory sig
    ) 
        external 
        whenNotPaused
        nonReentrant
         {


        // valida el hash con la firma
        require(
            recoverSigner(hash, sig) == _validator,
            "Cross:Not validated!"
        );

        require( _getHash( _msgSender(), pending, n1) == hash  , "Cross:Wrong transacction");

        require( _registered[_msgSender()].nonce2 < n1  , "Cross:Invalid transacction");

        // wcross a a creditar
        uint256 amount = pending;

        // pending viene  minificado
        if (_registered[_msgSender()].confirmed > 0)
            amount = pending.sub(_registered[_msgSender()].confirmed);

        //User amount should be limited
        require(toMax(amount) <= _limitAmount, "Cross:amount overflow");

        //se actualiza el nonce2
        _registered[_msgSender()].nonce2 = n1;

        // se agrega lo acreditado como confirmado
        _registered[_msgSender()].confirmed = _registered[_msgSender()]
            .confirmed
            .add(amount);

        //calculo  del  fee a descontar
        (uint256 net, uint256 fee) = calcFeesAndNet(
            toMax(amount),
            _fee,
            _baseFee
        );

        if (fee > 0 && _feeCollector != address(0)) {
            // envia  el fee a la cuenta recaudadora
            if (_isCrossOrigin) {

                TransferHelper.safeTransfer(address(_cross),_feeCollector, fee);

            } else {
                _cross.mint(_feeCollector, fee);
            }
        }

        if (_feeCollector != address(0)) {
            // si se cobra impuesto solo mintea  el neto
            if (_isCrossOrigin) {
                TransferHelper.safeTransfer(address(_cross),_msgSender(), net);

            } else {
                _cross.mint(_msgSender(), net);
            }
        } else {
            // si no se cobra se mintea el total
            if (_isCrossOrigin) {
                TransferHelper.safeTransfer(address(_cross),_msgSender(), toMax(amount));

            } else {
                _cross.mint(_msgSender(), toMax(amount));
            }
        }

        emit CrossReceived(_msgSender(), toMax(amount));

    }


    function emergencyWithdraw(uint256 _amount) public onlyOwner {
        require(_isCrossOrigin,"Cross: Withdraw is posible only in origin");
        require(
            _amount < _cross.balanceOf(address(this)),
            "Cross: Not enough token"
        );
        TransferHelper.safeTransfer(address(_cross),_msgSender(), _amount);
    }

}