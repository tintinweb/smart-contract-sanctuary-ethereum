/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface LW0 {
    function emitMint(address _to, string memory _tier) external;
    function getPrice() external view returns (uint256);
    function getAllowedTokensInBulk() external view returns (address[] memory, uint256[] memory);
    function getRoyaltyRecipient() external view returns (address);
}

interface IERC20 {                                                                                     
    function transfer(address _to, uint256 _amount) external returns (bool);                                       
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);         
    function balanceOf(address _owner) external view returns (uint256);                                 
    function approve(address _spender, uint256 _amount) external returns (bool);                        
    function allowance(address _owner, address _spender) external view returns (uint256);               
}                                                                                                       

contract LW0Minter {

    address private owner;
    address private ERC721ContractAddress;
    
    LW0 ERC721Contract;

    constructor(address _ERC721ContractAddress) {
        owner = msg.sender;
        ERC721ContractAddress = _ERC721ContractAddress;
        ERC721Contract = LW0(ERC721ContractAddress);
    }

    function manualMint(address _to, string memory _tier) public {
        require(_to != address(0), "LW0: zero address");
        require(msg.sender == owner, "Only owner can mint");
        ERC721Contract.emitMint(_to, _tier);
    }

    function mint(address _to) public payable {
        require(_to != address(0), "LW0: zero address");
        uint256 price = ERC721Contract.getPrice();
        require(msg.value >= price, "Not enough ETH sent");
        ERC721Contract.emitMint(_to, '');
        payable(ERC721Contract.getRoyaltyRecipient()).transfer(msg.value);
    }                                                                                                   

    function mintWithToken(address _to, address _token) public {
        require(_to != address(0), "LW0: zero address");
        IERC20 token = IERC20(_token);
        (address[] memory allowedTokens, uint256[] memory allowedTokenAmounts) = ERC721Contract.getAllowedTokensInBulk();
        uint256 tokenIndex = 0;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                tokenIndex = i;
                break;
            }
        }
        require(allowedTokenAmounts[tokenIndex] > 0, "Token not allowed");
        token.transferFrom(msg.sender, ERC721Contract.getRoyaltyRecipient(), allowedTokenAmounts[tokenIndex]);
        ERC721Contract.emitMint(_to, '');
    }

    function freeMint(address _to) public {
        require(_to != address(0), "LW0: zero address");
        require(msg.sender == owner, "Only owner can mint");
        ERC721Contract.emitMint(_to, '');
    }
}