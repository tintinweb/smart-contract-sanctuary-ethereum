//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


interface IERC20 {
    /**
    ///@notice importing only necessary IERC20 methods
    ///@notice GAS IS IMPORTANT
    */
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract Sender {
    /**
    Sender is a contract to execute multiple transfers(for example for an airdrop), 
    it allows transfer using the native coin of the blockchain or ERC20 tokens.

    The contract keeps the track of ether/erc20 tokens sent by the user and allows the user
    to send his allowed tokens to multple addresses using the sendEther/sendERC20Tokens respectively.

    ## ETHER / NATIVE COIN
    The user can send ether to the contract in 2 ways:
    - Sending ether directly to the contract via Metamask (it will be handled by receive and fallback functions)
    - Using addFunds function. 


    ## ERC20
    To add ERC20 tokens to the contract needs to follow these steps
    1 - approve x amount from the token contract to this contract
    2 - use addERC20Token function from this token. DO NOT SEND ERC20 TOKENS DIRECTLY AS RECEIVE FUNCTIONS ONLY HANDLES ETHER!!
    
    */
    
    ///@notice Log ether sent to contract
    ///@param from address who sent ether to the contract
    ///@param value amount of ether
    event Received(address from, uint256 value);

    ///@notice Log ether withdrawn from contract
    ///@param from address who sent ether
    ///@param to recipient address
    ///@param value amount of ether
    event SentEther(address from, address to, uint256 value);

    ///@notice Log ERC20 sent to contract
    ///@param token_address ERC20 token address
    ///@param from address who sent ERC20 to the contract
    ///@param value amount of ERC20
    event ReceivedERC20Token(address token_address, address from, uint256 value);

    ///@notice Log ERC20 withdrawn from contract
    ///@param token_address ERC20 token address
    ///@param from address who sent ERC20
    ///@param to recipient address
    ///@param value amount of ERC20
    event SentERC20Token(address token_address, address from, address to, uint256 value);

    /// @notice  A key-value list to track how much ether can be used per user.
    mapping(address=>uint256) public etherAllowances;
    /// @notice  A nested key-value list to track how much ERC20 can be used per user.
    mapping(address=>mapping(address=>uint256)) public erc20Allowances;

    constructor(){}
    
    ///@dev Function to receive Ether. msg.data must be empty
    receive() external payable {
        etherAllowances[msg.sender] += msg.value;
        emit Received(msg.sender,msg.value);
    }

    ///@dev Fallback function is called when msg.data is not empty
    fallback() external payable {
        etherAllowances[msg.sender] += msg.value;
        emit Received(msg.sender,msg.value);
    }
    
    ///@notice ether amount is sent in msg.value
    function addEther() external payable {
        etherAllowances[msg.sender] += msg.value;
        emit Received(msg.sender,msg.value);
    }

    ///@notice Transfer all allowed ether to msg.sender
    function withdraw() external payable{
        uint256 balance_of_user = etherAllowances[msg.sender];
        require(balance_of_user > 0, "no ether to withdraw");
        etherAllowances[msg.sender] = 0;
        (bool sent,) = address(msg.sender).call{value: balance_of_user}("");
        require(sent);
        emit SentEther(address(this), msg.sender, balance_of_user);
    }

    /// @param recipients list of addresses receiving the token
    /// @param values amount of ether(in wei) for each recipient
    function sendEther(address[] memory recipients, uint256[] memory values) external payable{
        uint256 total;
        for (uint256 i=0;i<values.length;i++){
            total+=values[i];
        }
        require(total <= etherAllowances[msg.sender], "you didnt supply enough ether");
        etherAllowances[msg.sender] -= total;
        for(uint256 i=0;i<recipients.length;i++){
            (bool sent, ) = recipients[i].call{value:values[i]}("");
            require(sent, "failed to send");
            emit SentEther(msg.sender, recipients[i],values[i]);
        }
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /*
        ERC20 METHODS
    */

    ///@param token_address ERC20 token address
    function getERC20Balance(address token_address) external view returns (uint){
        return IERC20(token_address).balanceOf(address(this));
    }

    ///@notice adds the user address to the erc20Allowances and increase its allowance
    ///@param token_address ERC20 token address
    ///@param amount amount of ERC20 tokens in wei
    function addERC20Token(address token_address, uint256 amount) external {
        erc20Allowances[msg.sender][token_address] += amount;
        require(IERC20(token_address).transferFrom(msg.sender, address(this), amount));
        emit ReceivedERC20Token(token_address, msg.sender, amount);
    }

    ///@notice removes all allowed tokens from msg.sender
    ///@param token_address ERC20 token address
    function removeERC20Token(address token_address) external {
        uint256 amount = erc20Allowances[msg.sender][token_address];
        erc20Allowances[msg.sender][token_address] = 0;
        
        require(IERC20(token_address).transfer(msg.sender,amount),"failed to withdraw ERC20");   

        emit SentERC20Token(token_address, address(this), msg.sender, amount);
    }

    ///@param token_address ERC20 token address
    /// @param recipients list of addresses receiving the token
    /// @param values amount of ether(in wei) for each recipient
    function sendERC20Token(address token_address,address[] memory recipients, uint256[] memory values) external {
        uint256 total;
        for (uint256 i=0;i<values.length;i++){
            total+=values[i];
        }
        require(total <= erc20Allowances[msg.sender][token_address], "you didnt supply enough ERC20");
        erc20Allowances[msg.sender][token_address] -= total;
        for(uint256 i=0;i<recipients.length;i++){
            require(IERC20(token_address).transfer(recipients[i],values[i]),"failed to send ERC20");        
            emit SentERC20Token(token_address, msg.sender, recipients[i], values[i]);
        }
    }
}