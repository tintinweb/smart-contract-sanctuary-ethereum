pragma solidity ^0.6.9;

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::: @#::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::: ########: ##:: jU* DUTCh>: ihD%Ky: #@Whdqy:::::::::::::::::::::
//::: ###... ###: ##:: #@j: @B... @@7...t: [email protected] [email protected]:::::::::::::::::::
//::: ##::::: ##: ##::[email protected]: @Q::: @Q.::::: [email protected]:: [email protected]:::::::::::::::::::
//:::: ##DuTCH##: %@[email protected]@S`: hQQQh <[email protected]@Q* [email protected]:: [email protected]:::::::::::::::::::
//::::::.......: [email protected]:::....:::......::...:::...:::::::::::::::::::
//:::::::::::::: [email protected]? [email protected]! 'DW;::::::.KK. [email protected]: NNKNQBdt:::::::::
//:::::::::::::: 'zqRqj*. [email protected] [email protected]: QQ: [email protected] [email protected] [email protected]@: @@U... @Q::::::::
//:::::::::::::::::...... [email protected]^ ^@@[email protected]@[email protected] <@Q^::: @@: @@}::: @@:::::::: 
//:::::::::::::::::: [email protected]@QKt... [email protected]@[email protected] [email protected]: @@QQ#QQq:::::::::
//:::::::::::::::::::.....::::::...:::...::::.......: @@!.....:::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::01101100:01101111:01101111:01101011::::::::::::::::::::
//:::::01100100:01100101:01100101:01110000:01111001:01110010:::::::::::
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// DutchSwap Factory
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// Appropriated from BokkyPooBah's Fixed Supply Token 👊 Factory
// https://www.ethervendingmachine.io
// Thanks Bokky!
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Owned.sol";
import "./SafeMathPlus.sol";
import "./CloneFactory.sol";
import "./IOwned.sol";
import "./IERC20.sol";
import "./IDutchAuction.sol";

contract DutchSwapFactory is  Owned, CloneFactory {
    using SafeMathPlus for uint256;

    address public dutchAuctionTemplate;

    struct Auction {
        bool exists;
        uint256 index;
    }

    address public newAddress;
    uint256 public minimumFee = 0 ether;
    mapping(address => Auction) public isChildAuction;
    address[] public auctions;

    event DutchAuctionDeployed(address indexed owner, address indexed addr, address dutchAuction, uint256 fee);
    
    event CustomAuctionDeployed(address indexed owner, address indexed addr);

    event AuctionRemoved(address dutchAuction, uint256 index );
    event FactoryDeprecated(address newAddress);
    event MinimumFeeUpdated(uint oldFee, uint newFee);
    event AuctionTemplateUpdated(address oldDutchAuction, address newDutchAuction );

    function initDutchSwapFactory( address _dutchAuctionTemplate, uint256 _minimumFee) public  {
        _initOwned(msg.sender);
        dutchAuctionTemplate = _dutchAuctionTemplate;
        minimumFee = _minimumFee;
    }

    function numberOfAuctions() public view returns (uint) {
        return auctions.length;
    }

    function addCustomAuction(address _auction) public  {
        require(isOwner());
        require(!isChildAuction[_auction].exists);
        bool finalised = IDutchAuction(_auction).auctionEnded();
        require(!finalised);
        isChildAuction[address(_auction)] = Auction(true, auctions.length - 1);
        auctions.push(address(_auction));
        emit CustomAuctionDeployed(msg.sender, address(_auction));
    }
    
    function removeFinalisedAuction(address _auction) public  {
        require(isChildAuction[_auction].exists);
        bool finalised = IDutchAuction(_auction).auctionEnded();
        require(finalised);
        uint removeIndex = isChildAuction[_auction].index;
        emit AuctionRemoved(_auction, auctions.length - 1);
        uint lastIndex = auctions.length - 1;
        address lastIndexAddress = auctions[lastIndex];
        auctions[removeIndex] = lastIndexAddress;
        isChildAuction[lastIndexAddress].index = removeIndex;
        if (auctions.length > 0) {
            auctions.pop();
        }
    }

    function deprecateFactory(address _newAddress) public  {
        require(isOwner());
        require(newAddress == address(0));
        emit FactoryDeprecated(_newAddress);
        newAddress = _newAddress;
    }
    function setMinimumFee(uint256 _minimumFee) public  {
        require(isOwner());
        emit MinimumFeeUpdated(minimumFee, _minimumFee);
        minimumFee = _minimumFee;
    }

    function setDutchAuctionTemplate( address _dutchAuctionTemplate) public  {
        require(isOwner());
        emit AuctionTemplateUpdated(dutchAuctionTemplate, _dutchAuctionTemplate);
        dutchAuctionTemplate = _dutchAuctionTemplate;
    }

    function deployDutchAuction(
        address _token, 
        uint256 _tokenSupply, 
        uint256 _startDate, 
        uint256 _endDate, 
        address _paymentCurrency,
        uint256 _startPrice, 
        uint256 _minimumPrice, 
        address payable _wallet
    )
        public payable returns (address dutchAuction)
    {
        dutchAuction = createClone(dutchAuctionTemplate);
        isChildAuction[address(dutchAuction)] = Auction(true, auctions.length - 1);
        auctions.push(address(dutchAuction));
        require(IERC20(_token).transferFrom(msg.sender, address(this), _tokenSupply)); 
        require(IERC20(_token).approve(dutchAuction, _tokenSupply));
        IDutchAuction(dutchAuction).initDutchAuction(address(this), _token,_tokenSupply,_startDate,_endDate,_paymentCurrency,_startPrice,_minimumPrice,_wallet);
        emit DutchAuctionDeployed(msg.sender, address(dutchAuction), dutchAuctionTemplate, msg.value);
    }

    // footer functions
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public returns (bool success) {
        require(isOwner());
        return IERC20(tokenAddress).transfer(owner(), tokens);
    }
    receive () external payable {
        revert();
    }
}

pragma solidity ^0.6.9;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

interface IDutchAuction {

    function initDutchAuction (
            address _funder,
            address _token,
            uint256 _tokenSupply,
            uint256 _startDate,
            uint256 _endDate,
            address _paymentCurrency,
            uint256 _startPrice,
            uint256 _minimumPrice,
            address payable _wallet
        ) external ;
    function auctionEnded() external view returns (bool);
    function tokensClaimed(address user) external view returns (uint256);
    function tokenSupply() external view returns(uint256);
    function wallet() external view returns(address);
    function minimumPrice() external view returns(uint256);
    function clearingPrice() external view returns (uint256);
    function auctionToken() external view returns(address);
    function endDate() external view returns(uint256);

    function paymentCurrency() external view returns(address);

}

pragma solidity ^0.6.2;
// SPDX-License-Identifier: UNLICENSED


interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

pragma solidity ^0.6.9;

// ----------------------------------------------------------------------------
// White List interface
// ----------------------------------------------------------------------------

interface IOwned {
    function owner() external view returns (address) ;
    function isOwner() external view returns (bool) ;
    function transferOwnership(address _newOwner) external;
}

pragma solidity ^0.6.9;

// ----------------------------------------------------------------------------
// CloneFactory.sol
// From
// https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
// ----------------------------------------------------------------------------

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

pragma solidity ^0.6.9;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts
 */
library SafeMathPlus {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a <= b ? a : b;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity ^0.6.9;


import "./IERC20.sol";


contract Owned {

    address private mOwner;   
    bool private initialised;    
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function _initOwned(address _owner) internal {
        require(!initialised);
        mOwner = address(uint160(_owner));
        initialised = true;
        emit OwnershipTransferred(address(0), mOwner);
    }

    function owner() public view returns (address) {
        return mOwner;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == mOwner;
    }

    function transferOwnership(address _newOwner) public {
        require(isOwner());
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(mOwner, newOwner);
        mOwner = address(uint160(newOwner));
        newOwner = address(0);
    }
    function recoverTokens(address token, uint tokens) public {
        require(isOwner());
        if (token == address(0)) {
            payable(mOwner).transfer((tokens == 0 ? address(this).balance : tokens));
        } else {
            IERC20(token).transfer(mOwner, tokens == 0 ? IERC20(token).balanceOf(address(this)) : tokens);
        }
    }
}