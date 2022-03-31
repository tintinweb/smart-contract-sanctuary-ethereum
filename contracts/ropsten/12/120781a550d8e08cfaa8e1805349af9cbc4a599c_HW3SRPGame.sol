//請使用 Rinkeby 測試網測試，不能用單機 VM 測試

pragma solidity ^0.4.11;

// import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.sol";
import "./oraclizeAPI_0.4.sol";

contract HW3SRPGame is usingOraclize {

    address public owner;
    mapping (bytes32 => address) public queryIdToPlayer; //queryId對應參賽者地址
    mapping (bytes32 => uint) public queryIdToMora; //queryId對應參賽者出拳樣式
    
    event guessEvent(bytes32 indexed queryId, address indexed player, uint indexed playerGuess);
    event resultEvent(bytes32 indexed queryId, uint indexed contractGuess, string result);
    
     // 結果準備好後，Oraclize調用回調函數
     // oraclize_randomDS_proofVerify修飾符可防止無效證明執行此功能代碼：
     //證明有效性在鏈上完全驗證
    function __callback(bytes32 _queryId, string _result, bytes _proof) public { 
        // 如果我們成功達到這一點，就意味著附加的真實性證明已經過去了！
        if (msg.sender != oraclize_cbAddress()) revert();
        
        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // 證明驗證失敗了，我們需要在這裡採取任何行動嗎？ （取決於案例）
            revert();
        } else {
            //證明驗證已通過
            //現在我們知道隨機數是安全生成的，讓我們使用它。
            // 為了簡單起見，如果需要，還可以將隨機字節轉換為uint
            uint maxRange = 3;
            // // 這是我們想要獲得的最高價。 它永遠不應該大於2 ^（8 * N），其中N是我們要求數據源返回的隨機字節數
            uint contractGuess = uint(keccak256(abi.encodePacked(_result))) % maxRange + 1;
            uint playerGuess = queryIdToMora[_queryId];

            string memory ans = "Tie";
            if (playerGuess == contractGuess) {
                queryIdToPlayer[_queryId].transfer(0.1 ether);
            } else if ((playerGuess == 1 && contractGuess == 3) || (playerGuess == 2 && contractGuess == 1) || (playerGuess == 3 && contractGuess == 2)) {
                queryIdToPlayer[_queryId].transfer(0.2 ether);
                ans = "Win";
            } else {
                ans = "Lose";
            }

            emit resultEvent(_queryId, contractGuess, ans);
        }
    }
    
    function update() public returns(bytes32) { 
        uint N = 7; // 我們希望數據源返回的隨機字節數
        uint delay = 0; // 執行發生前等待的秒數
        uint callbackGas = 200000; // 我們希望Oraclize為回調函數設置的gas量
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // 此函數在內部生成正確的oraclize_query並返回其queryId
        return queryId;
    }

    //1代表剪刀，2代表石頭，3代表布
    function guess(uint gesture) payable public {
        require(msg.value == 0.01 ether, "play game need 0.01 ether.");
        require(gesture >= 1 && gesture <= 3, "please enter a valid value. 1-剪刀,2-石頭,3-布");
        
        bytes32 queryId = update(); 
        queryIdToPlayer[queryId] = msg.sender;
        queryIdToMora[queryId] = gesture;
        
        emit guessEvent(queryId, msg.sender, gesture);
    }

    function validRamdon(string randomDS) public pure returns(uint) {
        return uint(keccak256(abi.encodePacked(randomDS))) % 3 + 1;
    }

    function contractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function sendMoney() payable public {
    }

   constructor() payable public {
       owner = msg.sender;
       oraclize_setProof(proofType_Ledger); // 在構造函數中設置Ledger真實性證明
    }

    function killcontract() public {
        require(msg.sender == owner, "not owner");
        //合約內的餘額轉給 owner
        owner.transfer(address(this).balance);
        selfdestruct(msg.sender);
    }

}