/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

/**

ooooooooooooo oooo                                                                               
8'   888   `8 `888                                                                               
     888       888 .oo.    .ooooo.                                                               
     888       888P"Y88b  d88' `88b                                                              
     888       888   888  888ooo888                                                              
     888       888   888  888    .o                                                              
    o888o     o888o o888o `Y8bod8P'                                                              
                                                                                                                                                                                                                                                                                         
  .oooooo.                .o8                                                                    
 d8P'  `Y8b              "888                                                                    
888          oooo    ooo  888oooo.   .ooooo.  oooo d8b                                           
888           `88.  .8'   d88' `88b d88' `88b `888""8P                                           
888            `88..8'    888   888 888ooo888  888                                               
`88b    ooo     `888'     888   888 888    .o  888                                               
 `Y8bood8P'      .8'      `Y8bod8P' `Y8bod8P' d888b                                              
             .o..P'                                                                              
             `Y8P'                                                                               
                                                                                                 
oooooooooooo                 .                                           o8o                     
`888'     `8               .o8                                           `"'                     
 888         ooo. .oo.   .o888oo  .ooooo.  oooo d8b oo.ooooo.  oooo d8b oooo   .oooo.o  .ooooo.  
 888oooo8    `888P"Y88b    888   d88' `88b `888""8P  888' `88b `888""8P `888  d88(  "8 d88' `88b 
 888    "     888   888    888   888ooo888  888      888   888  888      888  `"Y88b.  888ooo888 
 888       o  888   888    888 . 888    .o  888      888   888  888      888  o.  )88b 888    .o 
o888ooooood8 o888o o888o   "888" `Y8bod8P' d888b     888bod8P' d888b    o888o 8""888P' `Y8bod8P' 
                                                     888                                         
                                                    o888o                                                                                                                                                                                                                                                                                                                        
     .ooooo.   .ooooo.  ooo. .oo.  .oo.                                                          
    d88' `"Y8 d88' `88b `888P"Y88bP"Y88b                                                         
    888       888   888  888   888   888                                                         
.o. 888   .o8 888   888  888   888   888                                                         
Y8P `Y8bod8P' `Y8bod8P' o888o o888o o888o                                                        


*/

pragma solidity ^0.8.9;

// libraries ( safe math , addresses ) ; 
library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// interfaces ( IERC20 , IUniswapV2Factory , IUniswapV2Pair , IUniswapV2Router01 , IUniswapV2Router02) ; 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract CYBR is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address private BURN_ADDRESS = 0xFeED01000011010110010100001001010010dEAD;

    // RE-DONE variables
    string private _name = "CYBR";
    string private _symbol = "CYBR";
    uint256 private _totalSupply = 1000000000000000 * 10 ** 18; // 1,000,000,000,000,000 supply + 18 decimals

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // CREATE NEW VARAIBLES:
    mapping (address => bool) private _pool;
    mapping (address => uint256) private _latestTransaction;
    mapping (address => bool) private _blacklist;
    mapping (address => bool) private _protected;

    uint256 private checkTime;
    // Times in in Seconds
    uint256 constant fiveMinutes = 300;
    uint256 constant minute      = 60;
    uint256 constant halfMinute  = 30;
    uint256 constant tenSeconds  = 10;

    // OLD ANTIbot
    // // Anti Bot - trade 
    // bool public antibotEnabled  ; 
    // uint256 public antiBotDuriation = 10 minutes ; 
    // uint256 public antiBotTime ; 
    // uint256 public antiBotAmount ; 

    mapping(address => bool) private botAddresses ; 

    bool public tradingOpen = false;

    constructor() {
        checkTime = tenSeconds;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // enable trading 
    function openTrading() external onlyOwner {
        tradingOpen = true;
    }
    // disable trading 
    function disableTrading() external onlyOwner{
       tradingOpen = false ; 
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    function totalBurned() public view returns (uint256) {
        return balanceOf(BURN_ADDRESS);
    }
    function _burn(uint256 amount) public{
          _balances[_msgSender()] = _balances[_msgSender()].sub(amount) ; 
          _balances[BURN_ADDRESS] = _balances[BURN_ADDRESS].add(amount) ; 
    }
    // add an address to the botaddresses to prevent from anti bot 
     function setBotAddresses (address[] memory _addresses) external onlyOwner {
        require(_addresses.length > 0);

        for (uint256 index = 0; index < _addresses.length; index++) {
            botAddresses[address(_addresses[index])] = true;
        }
    }

    // Galib's ANTI-BOT function
    // function antiBot(uint256 amount) external onlyOwner {
    //     require(amount > 0, "not accept 0 value");
    //     require(!antibotEnabled);

    //     antiBotAmount = amount;
    //     antiBotTime = block.timestamp + antiBotDuriation;
    //     antibotEnabled = true;
    // }
    
    function transfer(address recipient, uint256 amount)
        public
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != BURN_ADDRESS);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 blocktime = block.timestamp;

        if(_pool[recipient]) {
            if(_blacklist[sender]) {
                revert();
            } else {
                if (_protected[sender]) {
                    transfer_(sender, recipient, amount, blocktime);
                } else {
                    if (block.timestamp - _latestTransaction[sender] < checkTime) {
                        _blacklist[sender];
                    } else {
                        transfer_(sender, recipient, amount, blocktime);
                    }
                }
            }
        } else {
            transfer_(sender, recipient, amount, blocktime);
        }
    }

    function transfer_(address sender, address recipient, uint256 amount, uint256 blockTime) private {
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        
        _latestTransaction[sender] = blockTime;

        _afterTokenTransfer(sender, recipient, amount);
    }

    function addPoolAddress(address pool) public onlyOwner {
        _pool[pool] = true;
    }

    function removePoolAddress(address pool) public onlyOwner {
        _pool[pool] = false;
    }

    function removeFromBlacklist(address adr) public onlyOwner {
        _blacklist[adr] = false;
    }

    function addProtectedAddress(address adr) public onlyOwner {
        _protected[adr] = true;
    }


    function removeProtectedAddress(address adr) public onlyOwner {
        _protected[adr] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // Galib's code    
    // transfer tokens from sender to recipient 
    // function _transferStandard(
    //     address sender,
    //     address recipient,
    //     uint256 tAmount
    // ) private {
    //     _balances[sender] = _balances[sender].sub(tAmount);
    //     _balances[recipient] = _balances[recipient].add(tAmount);
    //     emit Transfer(sender, recipient, tAmount);
    // }
}