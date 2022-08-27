/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20MintOrBurn is IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
    function burn(uint256 _amount) external ;
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
}

interface IPriceAggrete{
    function price() external view returns(uint256);
    function pair() external view returns(string memory);
}

contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  uint256[50] private ______gap;

}

contract Ownable {

    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function owner() external view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        setOwner(newOwner);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }


    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }
}

contract Blacklistable is Ownable {
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "Blacklistable: account is blacklisted"
        );
        _;
    }

    function isBlacklisted(address _account) external view returns (bool) {
        return blacklisted[_account];
    }

    function blacklist(address _account) external onlyOwner {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    function unBlacklist(address _account) external onlyOwner {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }
}

library Address {
 
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash= 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

   
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

   
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{
            value: weiValue
        }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

   
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract ICOExchange is Ownable, Pausable, Blacklistable, Initializable {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    IPriceAggrete public priceAggregater;
    IERC20MintOrBurn public inrX;
    IERC20 public usdt;

    

    function initialize (IERC20MintOrBurn _inrXToken, IERC20 _usdt, IPriceAggrete _aggreater,address own) initializer external returns (bool) {
        priceAggregater = _aggreater;
        inrX = _inrXToken;
        usdt   = _usdt;
        setOwner(own);
        return true;
    }

    function deposit(uint256 _usdAmount)  external whenNotPaused returns (bool) {
        uint256 _usdtPrice = priceAggregater.price();
        require(usdt.allowance(msg.sender,address(this))>=_usdAmount,"ICOExchange :: allowance exceed");
        require(usdt.balanceOf(msg.sender)>=_usdAmount,"ICOExchanage :: low balance");
        uint256 _inrxAmount = _usdtPrice*1e16*_usdAmount;
        usdt.transferFrom(msg.sender,address(this),_usdAmount);
        inrX.mint(msg.sender,(_inrxAmount/1e18));
        return true;
    } 


    function withdraw(uint256 _inrAmount)  external whenNotPaused returns (bool) {
        uint256 _usdtPrice = priceAggregater.price();
        require(inrX.allowance(msg.sender,address(this))>=_inrAmount,"ICOExchange :: allowance exceed");
        require(inrX.balanceOf(msg.sender)>=_inrAmount,"ICOExchanage :: low balance");
        uint256 _inrxAmount = ((_inrAmount*1e18)/(_usdtPrice*1e16));     
        inrX.transferFrom(msg.sender,address(this),_inrAmount);
        inrX.burn(_inrAmount);
        usdt.transfer(msg.sender,_inrxAmount);
        return true;
    } 

    function usdPrice() public view returns (uint256) {
        return priceAggregater.price();
    } 

    
    function rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) external onlyOwner {
        tokenContract.safeTransfer(to, amount);
    }


}