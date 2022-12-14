/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ChristmasDonation{
    event DonationEvent(address indexed donor, string name, string email, string donation_message, string decoration, address token_address, uint token_amount, uint amount);

    /*  decoration list which is selected by donor
    */
    string[] public decoration = [  //  change the decoration list 
        "gingerbreads", "flowers", "lights", "ornaments", "presents", "snowflakes",
        "snowman", "stars", "stockings", "sugarplums", "trees", "wreaths"
    ];

    struct Donation{
        string name;
        string email;
        string donation_message;
        uint decoration_index;
        address token_address;
        uint token_amount;
        uint amount;
    }

    mapping(address => bool) public allowedTokens;
    mapping(address => uint) public tokenBurned;

    Donation[] public donations;
    address public owner;
    address public donationAddress = 0x4757Bbf9Ca5abF2EE719086ed9F3473D6C305D70;  
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    /*  add token address to allowed Tokens list
        param: tokenaddr - token address
    */
    function addToken(address tokenaddr) external onlyOwner{
        allowedTokens[tokenaddr] = true;
    }

    /*  remove token address from allowed Tokens list
        param: tokenaddr - token address
    */
    function removeToken(address tokenaddr) external onlyOwner{
        allowedTokens[tokenaddr] = false;
    }

    /*  donate function to donate ethers and burn tokens
        param: tokenaddr - token address
        param: token_amount - token amount
        param: name - donor name
        param: email - donor email
        param: donation_message - donation message
        param: decoration_index - decoration index
    */
    function donate(IERC20 tokenaddr,uint token_amount, string memory name, string memory email, string memory donation_message, uint decoration_index) external payable{
        require(decoration_index<decoration.length && decoration_index>=0, "Invalid decoration index");
        
        if (token_amount != 0){
            require(allowedTokens[address(tokenaddr)], "Token not allowed");
            require(tokenaddr.balanceOf(msg.sender) >= token_amount, "Insufficient token balance");
            require(tokenaddr.allowance(msg.sender, address(this)) >= token_amount, "Insufficient token allowance");
            tokenaddr.transferFrom(msg.sender, deadAddress, token_amount);
            tokenBurned[address(tokenaddr)] += token_amount;
        }
        
        payable(donationAddress).transfer(msg.value);
        donations.push(Donation(name, email, donation_message, decoration_index, address(tokenaddr), token_amount, msg.value));
        emit DonationEvent(msg.sender, name, email, donation_message, decoration[decoration_index], address(tokenaddr), token_amount, msg.value);
        
    }

    /*  get amount of tokens burned
        param: tokenaddr - token address
        return: amount of tokens burned
    */
    function getTokenBurnedAmount(address tokenaddr) external view returns(uint){
        return tokenBurned[tokenaddr];
    }

    /*  get donation list
        return: donation list
    */
    function getDonations() external view returns(Donation[] memory){
        return donations;
    }
    
    /*  get donation by index
        param: index - donation index
        return: donation
    */
    function getDonation(uint index) external view returns(Donation memory){
        return donations[index];
    }
}