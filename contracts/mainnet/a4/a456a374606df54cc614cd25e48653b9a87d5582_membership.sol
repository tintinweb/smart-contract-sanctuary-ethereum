/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;



interface Imembership
{
     

    function awardmembership (address memberaddress, uint256 level) external;

    function getmembershiplevel (address memberaddress) external view returns (uint256);

    function buymembership (uint256 level) external payable;

    function setmembershipprice (uint256 price, uint256 level) external;

    function getmembershipprice (uint256 level) view external returns(uint256);

    function setbadge(string calldata badgename, address user ) external; 

    function getbadge(string calldata badgename, address user ) view external returns(bool); 

    function addnewowner (address newowner) external;

    function transferamount(address rec, uint256 amount) external;

    function getbalance() external view returns (uint256);

}

contract ReentrancyGuard {
  bool private _notEntered;

  constructor () {
    // Storing an initial non-zero value makes deployment a bit more
    // expensive, but in exchange the refund on every call to nonReentrant
    // will be lower in amount. Since refunds are capped to a percetange of
    // the total transaction's gas, it is best to keep them low in cases
    // like this one, to increase the likelihood of the full refund coming
    // into effect.
    _notEntered = true;
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
    require(_notEntered, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _notEntered = false;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _notEntered = true;
  }
}


contract membership is Imembership, ReentrancyGuard {

    //multiowner code


    constructor(address[] memory _owners) {

        _membershipleveltoprice[1] = 200000000000000000;
        _membershipleveltoprice[2] = 500000000000000000;
        _membershipleveltoprice[3] = 2000000000000000000;
        _membershipleveltoprice[4] = 10000000000000000000;
        _membershipleveltoprice[5] = 1000000000000000000000;



        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

    }

    

    mapping(address => bool) public isOwner;

    address[] public owners;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }


     mapping(address => uint256) private _membershiplevel;

     mapping(uint256 => uint256) private _membershipleveltoprice;

     mapping(address => uint256) public _membershipdate;

     mapping(address => uint256[]) private _badges;

     mapping(string => mapping(address => bool)) private badge;



function addnewowner (address newowner) onlyOwner override external
{

 require(newowner != address(0), "invalid owner");
            require(!isOwner[newowner], "owner not unique");

            isOwner[newowner] = true;
            owners.push(newowner);


}

function awardmembership (address memberaddress, uint256 level) onlyOwner override external 

{

_membershiplevel[memberaddress] = level;
_membershipdate[memberaddress] = block.timestamp;

}

    function buymembership (uint256 level) override external payable nonReentrant
    {

    require (_membershipleveltoprice[level] <= msg.value, "Price does not match requested membership level");

    _membershiplevel[msg.sender] = level;
    _membershipdate[msg.sender] = block.timestamp;




}

function setmembershipprice (uint256 price, uint256 level) override external onlyOwner
{

_membershipleveltoprice[level] = price;

}

function getmembershipprice (uint256 level) override view external returns(uint256)
{

return _membershipleveltoprice[level];

}


function getmembershiplevel (address memberaddress) override external view returns (uint256)

{

return _membershiplevel[memberaddress];

}


function getbadge(string calldata badgename, address user ) override external view returns (bool) {

return badge[badgename][user];

}

function getbalance() override external view returns (uint256) {

return address(this).balance;

}

function transferamount(address rec, uint256 amount) override external onlyOwner nonReentrant
{
    require (address(this).balance >= amount, "Insufficient balance");

    payable(rec).transfer(amount);
}


function setbadge(string calldata badgename, address user ) override external onlyOwner {

 badge[badgename][user] = true;

}

}