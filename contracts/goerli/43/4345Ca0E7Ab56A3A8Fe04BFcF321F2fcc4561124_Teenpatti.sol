// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Teenpatti{
    
    string  public name = "Teen-patti";
    string  public symbol = "ACE";
    
    uint256 private totalSupply;
    uint256 public tokenPrice;
    uint256 public etherAmount;
    address payable owner;
    
  
    address payable[] public inGamePlayers;
    address[] Players = new address[](4);

    // address to balance
    mapping (address => uint256) public balanceOf;
    
    mapping(address => uint256[]) public allplayer;
    
    constructor (uint256 initialSupply,uint256 pricePerToken) public {
        owner = payable(msg.sender);
        totalSupply = initialSupply;
        balanceOf[owner] = totalSupply;
        tokenPrice = pricePerToken;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    
    function buyTokens(uint numberOfTokens) public payable returns (bool){
        require(msg.value == multiply(numberOfTokens, tokenPrice),"Insufficient ether for required amount of tokens");
        require(balanceOf[owner] > numberOfTokens,"Insufficient Liquidity for this token");
        balanceOf[owner] -= numberOfTokens;
        balanceOf[msg.sender] += numberOfTokens;    
        etherAmount += msg.value;
        return true;
    }

    
    function winer(address receiver, uint256 numberOfTokens)public returns (bool){
        require(numberOfTokens <= balanceOf[msg.sender]);
        balanceOf[msg.sender] = balanceOf[msg.sender] -= numberOfTokens;
        balanceOf[receiver] = balanceOf[receiver] += numberOfTokens;
        return true;
    }

    function getBalance() public view returns (uint256) {
        return balanceOf[msg.sender];
    }

    function randm(
        uint256 num,
        address payable p1,
        address payable p2,
        address payable p3,
        address payable p4
    )
        public
        onlyOwner
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        inGamePlayers.push(p1);
        inGamePlayers.push(p2);
        inGamePlayers.push(p3);
        inGamePlayers.push(p4);

        uint256[] memory arr = new uint256[](12);
        uint256 dif = block.difficulty;

        
        Players[0] = p1;
        Players[1] = p2;
        Players[2] = p3;
        Players[3] = p4;

        for (uint256 i = 0; i < 12; i++) {
            dif += i;
            arr[i] =
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, dif, msg.sender)
                    )
                ) %
                num;
            uint256 index = i % 4;
            allplayer[Players[index]].push(arr[i]);
        }
        uint256 player1sum = playerSum(p1);
        uint256 player2sum = playerSum(p2);
        uint256 player3sum = playerSum(p3);
        uint256 player4sum = playerSum(p4);

        return (player1sum, player2sum, player3sum, player4sum);
    }

    function getplayervalue(address hk) public view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        // uint256 sum = 0;
        return allplayer[hk];
    }

    function playerSum(address payable xyz) public view returns (uint256) {
        return allplayer[xyz][0] + allplayer[xyz][1] + allplayer[xyz][2];
    }

    function arrLen() public view returns(uint){
        return inGamePlayers.length;
    }

    function WinnerAdrs() public view returns (address) {
        address ad;
        uint256 winer;

        for (uint256 i = 0; i < inGamePlayers.length; i++) {
            if (winer < playerSum(inGamePlayers[i])) {
                winer = playerSum(inGamePlayers[i]);
                ad = inGamePlayers[i];
            }
        }
        return ad;
    }

    function blind(uint numberOfTokens) public returns (bool) {
        require(numberOfTokens <= balanceOf[msg.sender]);
        require(
            balanceOf[msg.sender] > numberOfTokens,
            "Insufficient Liquidity for this token"
        );
        balanceOf[msg.sender] -= numberOfTokens;
        balanceOf[owner] += numberOfTokens;
        return true;
    }

    function Show(uint numberOfTokens) public returns (bool) {
        require(numberOfTokens <= balanceOf[msg.sender]);
        require(
            balanceOf[msg.sender] > numberOfTokens,
            "Insufficient Liquidity for this token"
        );
        balanceOf[msg.sender] -= numberOfTokens;
        balanceOf[owner] += numberOfTokens;
        return true;
    }

}