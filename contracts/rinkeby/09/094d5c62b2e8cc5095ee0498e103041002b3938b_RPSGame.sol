pragma solidity >= 0.5.0 < 0.6.0;

//import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";
import "./provable.sol";

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract RPSGame is Ownable, usingProvable {
    using SafeMath for uint;
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    event gameResult(address user, string userChoice, string dealerChoise);
    uint public new_random;
    uint public test;
    address public addr;
    bytes32 public id;

    struct GameInfo {
        address payable player;
        uint choice;
        bool verified;
    }

    mapping (bytes32=>GameInfo) public game;

    // constructor() payable public {
    //     oraclize_setProof(proofType_Ledger); // 在構造函數中設置Ledger真實性證明
    //     //update(); //在合同創建時，我們立即要求N個隨機字節！
    // }
    
     // 結果準備好後，Oraclize調用回調函數
     // oraclize_randomDS_proofVerify修飾符可防止無效證明執行此功能代碼：
     //證明有效性在鏈上完全驗證
    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public
    { 
        test = 0;
        // 如果我們成功達到這一點，就意味著附加的真實性證明已經過去了！
        if (msg.sender != provable_cbAddress()) revert();

        if (provable_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // 證明驗證失敗了，我們需要在這裡採取任何行動嗎？ （取決於案例）
        } else {
            //證明驗證已通過
            //現在我們知道隨機數是安全生成的，讓我們使用它。
            emit newRandomNumber_bytes(bytes(_result)); //  这是结果随机数 (bytes)
            
            // 為了簡單起見，如果需要，還可以將隨機字節轉換為uint
            uint maxRange = 2**(8* 7);
            // 這是我們想要獲得的最高價。 它永遠不應該大於2 ^（8 * N），其中N是我們要求數據源返回的隨機字節數
            uint randomNumber = uint(keccak256(abi.encodePacked(_result))) % maxRange;
            // 這是在[0，maxRange]範圍內獲取uint的有效方法
            // new_random = randomNumber;
            Result(_queryId,randomNumber%3+1);

            emit newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)
        }
    }
    
    
    function Result(bytes32 uid ,uint num) internal {
        GameInfo memory gameplay = game[uid];
        require(gameplay.verified == false);
        if (gameplay.choice == num){
            gameplay.player.transfer(0.01 ether);
            emit gameResult(gameplay.player, choice_str(gameplay.choice), choice_str(num));
        }
        else if ((gameplay.choice == 1 && num == 3) || (gameplay.choice == 2 && num == 1) || (gameplay.choice == 3 && num == 2) ){
            gameplay.player.transfer(0.02 ether);
            emit gameResult(gameplay.player, choice_str(gameplay.choice), choice_str(num));
        }
        else{
            emit gameResult(gameplay.player, choice_str(gameplay.choice), choice_str(num));
        }
        game[uid].verified = true;
    }

    function choice_str(uint item) internal pure returns(string memory) {
        if (item == 1) return "Scissors";
        if (item == 2) return "Rock";
        if (item == 3) return "Paper";
        return "invalid item";
    }

    function play(uint choice) payable public{
        require(choice == 1 || choice == 2 || choice == 3, "invalid choice"); // 1 剪刀 2石頭 3布
        require(msg.value == 0.01 ether);

        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 200000; // 我們希望Oraclize為回調函數設置的gas量
        bytes32 queryId = provable_newRandomDSQuery(delay, N, callbackGas); // 此函數在內部生成正確的oraclize_query並返回其queryId
        id = queryId;
        game[queryId] = GameInfo(msg.sender,choice,false);
    }
    
}