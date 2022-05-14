/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: AAL

// ██████╗  ██████╗  ██████╗ █████╗  █████╗  █████╗  █████╗  █████╗  █████╗  █████╗    ███████╗████████╗██╗  ██╗
//██╔════╝ ██╔════╝ ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗   ██╔════╝╚══██╔══╝██║  ██║
//███████╗ ███████╗ ███████╗╚██████║╚██████║╚██████║╚██████║╚██████║╚██████║╚██████║   █████╗     ██║   ███████║
//██╔═══██╗██╔═══██╗██╔═══██╗╚═══██║ ╚═══██║ ╚═══██║ ╚═══██║ ╚═══██║ ╚═══██║ ╚═══██║   ██╔══╝     ██║   ██╔══██║
//╚██████╔╝╚██████╔╝╚██████╔╝█████╔╝ █████╔╝ █████╔╝ █████╔╝ █████╔╝ █████╔╝ █████╔╝██╗███████╗   ██║   ██║  ██║
// ╚═════╝  ╚═════╝  ╚═════╝ ╚════╝  ╚════╝  ╚════╝  ╚════╝  ╚════╝  ╚════╝  ╚════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝
                                                                                                              
pragma solidity ^0.8.5;

interface IERC20 {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256);
    function name() external view returns (string memory);
}

contract TokenAccept {
    address private owner;
    IERC20[] private token20;
    string[] private token20Name;
    address private contractAddress = address(this);

    constructor () {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    //BASIC START
    // [CHECKED]
    function getOwner() public view returns (address) {
        return owner;
    }
    //BASIC END

    // ERC20 TOKEN VIEW START
    // [CHECKED]
    function getNameByTokenIndex(uint256 _tokenIndex) public view returns (string memory tokenName) {
        return token20[_tokenIndex].name();
    }

    // [CHECKED]
    function getBalanceByTokenIndex(uint256 _tokenIndex) public view returns (uint256){
        return token20[_tokenIndex].balanceOf(contractAddress);
    }
    
    // [CHECKED]
    function getTokenNameArray() public view returns(string[] memory){
        return token20Name;
    }
    // ERC20 TOKEN VIEW END

    // ERC20 TOKEN FUNCTION START
    // [CHECKED]
    function withdrawByTokenId(uint256 _tokenIndex) public isOwner{
        require(token20.length > _tokenIndex, "Illegal _tokenIndex");
        IERC20 item = token20[_tokenIndex];
        item.transfer(owner,getBalanceByTokenIndex(_tokenIndex));
    }

    // [CHECKED]
    function transferByTokenId(uint256 _tokenIndex, address _recipient,uint256 _amount) public isOwner{
        require(token20.length > _tokenIndex, "Illegal _tokenIndex");
        IERC20 item = token20[_tokenIndex];
        item.transfer(_recipient,_amount);
    }

    // [CHECKED]
    function addToken(IERC20 _ierc20) public isOwner{
        for(uint256 i = 0; i < token20.length; i++){
            IERC20 item = token20[i];
            require(item != _ierc20, "Repeat Token");
        }
        token20.push(_ierc20);
        token20Name.push(_ierc20.name());
    }
    // ERC20 TOKEN FUNCTION END

    // MAIN TOKEN VIEW START
    // [CHECKED]
    function getBalanceByMainToken() public view returns(uint256){
        return contractAddress.balance;
    }

    fallback() external payable {}
    receive() external payable {}
    // MAIN TOKEN VIEW END

    // MAIN TOKEN FUNCTION START
    // [CHECKED]
    function withdrawByMainToken() public isOwner{
        payable(owner).transfer(getBalanceByMainToken());
    }

    // [CHECKED]
    function transferByMainToken(address _recipient, uint256 _amount) public isOwner{
        payable(_recipient).transfer(_amount);
    }
    // MAIN TOKEN FUNCTION END
}