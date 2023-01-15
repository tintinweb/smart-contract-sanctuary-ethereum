/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT

/**

DO NOT FADE THIS: READ THE NOTE BELOW, and DOWNLOAD VOl.1 from the TG Channel.

Forget the token. As things stand, this was the only way I could gain your attention. 
There is no need to buy or sell this as it offers nothing. 

Welcome to Vol 1. of the Theories of Treason: The Octopus

Want to know who Satoshi is? The Answer is within
Want to know who is the "CEO" of BTC? The Answer is within
Want to know the truth about Vitalik? The Answer is within
Want to know why exchanges blew up and regulations are suddenly appearing? The Answer is within
Want to know the ugly dark side of the CBDC? The Answer is within

Everything you feared, is true. Everything we brushed off as conspiracy, is true. 
This is one mans journey to awaken the sleeping sheep, will you join me? 
I tried to get this on reddit and youtube but they shut me down. My Twitter account has been suspended. 
I cannot make a website for this, or at least at the moment dont know how to go about it)
I explored making an NFT for these but I lack the skills and the document is 30+ pages. 
Maybe I will try to take screenshots of each page and have an NFT made of it. 


Please read carefully below before walking with me.
This is not a utility token or a meme token or even a larp. This is a series of books. 
The intention of the author was to have these published as short stories however no publisher seems willing 
to touch this with a bargepole for obvious reasons. 

Please raise your voices to have Elon unban the Twitter account @TreasonOctopus - as all the answers lie there. 
They will tell you its not True. It is.
They will tell you its a conspiracy theory. It is NOT. 
They will tell you you are right wing. The right wing is actually worse, and comprise a majority of the Octopus.

- Go spread the word - Now is the time Anon, before it's too late. They almost have us by the balls. We need to stand up.

Below is an excert from the book: 

Foreword: 
One day you’re an asset… The next day you’re a fucking afterthought. 
This succinct one-liner from an otherwise kitsch motion picture, is poignant for more 
reasons than most would care to remember. In a dystopian world divided by everything imaginable 
(wealth, religion, color, education, political beliefs, gender) it’s hard to keep track of the real. 
It’s even harder, to keep track of the unreal. 

Therefore, this trifling endeavor of putting keystroke to WordPad in an attempt to sort of, make sense of it all.
The thing about miasma is it’s easy to identify, but frightfully difficult to rid. The putrid remains then often 
have to be dealt with in the most unscientific manner. Collateral damage.
We shall begin then with the usual pleasantries and hope you detest this read as much as I detested having to compile it. 
Detest we both will, because it is despicable, dastardly, and downright damning. 
I urge you to spend some time away from the humdrum of mainstream and dive headlong into the chasm of fear, 
uncertainty and doubt that I attempt to weave. 

As the words unfold, grudge me not the untimely digressions or the occasional rant for I am but an ordinary human, 
fallible and prone to excitement. Pardon my most feeble attempts to piece together some of the most disgusting 
machinations of a system gone depraved and broken to its core. 

A word to the penitent and contrite, your devotion is much appreciated whilst in effect wholly unbecoming 
because the purpose of this reading is to have you take a step back and think. Ponder over your lives, 
your mundane existences, your inconsequential and drab attempts at making it to the end of the line as a 
faithful lamb to the slaughter at which point the legacy you leave behind is futile, the value you brought 
to the world around you, zero. Is there not then, some obvious room for improvement. 

May you not then pick up the gauntlet and become a beacon of light for those around you? 
Would it not be worth your while to seek answers to questions that havr put you and your loved ones in harms way? 
Probably not, for if you had it in you, the world wouldn’t be the shithole that it is. 

Let’s face it, you are content being sheep, you are masochists that relish the slaughter. 
You want the expected, the safety, the comfort, regardless of it being a complete and obvious lie. 
I bring not positive tidings nor salacious fodder. 
I seek but to lay out events of note, that have some open ends, 
and flirt with that word all of humanity should spend 5 minutes thinking about daily: 
COINCIDENCE. 

We move on without further ado then, let the fuckery of coincidences commence. 
Regardless of your opinions on the topics discussed, I remain deeply obliged, with warmest commiserations,
The Man with No Name

END
******************************************************

PS: I own no tokens and neither plan to purchase any. The part-time solidity dev engaged for this (Thanks Dave), he will 
pick up some tokens at launch, please do not grudge his meagre purchase designed to pay for his services. 
It would be great if a community could form around this to continue the movement. 
My personal recommendation, you do not have to buy or sell this token, its just a way for me to reach you. 
But use its existence to build awareness of it. Dave wil lock liquidity for a week or two. I cannot be blocking $ at this time 
because I fear soon I will be on the run and need every $ I get as the future volumes come out. 

This movement needs YOUR BELIEF AND SUPPORT TO SPREAD THE WORD. 

Rest assured Vol 2. will be a lot more detailed. 

For now: t.me/TreasonOctopus
This will remain as long as I can keep myself safe and communicating. Am pretty sure they will come for me. 
If you hear any news regarding a sudden disappearance of the writer of these short stories. Know that I was taken.  
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract OCTOPUS is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_); // Optional
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
}