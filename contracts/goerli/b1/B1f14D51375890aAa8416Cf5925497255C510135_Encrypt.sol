// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Accessable.sol";
import "./interfaces/IRandom.sol";
import "./interfaces/ICrypten.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract Encrypt is Accessable {
    
    event Log(int256[] data, bytes32 extras);
    event Log(uint256[] data, bytes32 extras);
    event ChangeCrypten(address newCrypten);
    mapping(bytes32 => int256[]) keys;
    uint256 number = 43;
    uint256[] dataEncryptionKey;
    ICrypten public crypten;
    constructor(){
        dataEncryptionKey = [164094632,68009222,186978779,136218760,204229199,100503016,8088023,18430882,128554729,30437764,159255618,116464225,18917728,55065563,11251761,8723697,149183006,23545186,200841142,156264450,195341591,156319041,141822512,144148445,155025312,200575419,66252446,46686158,80906141,169418726,5481566,38515403,116609952,136927846,150596615,46097482,145810751,145816799,44373429,72569051,187920556,207975511,34669264,99762139,116665018,121511432,130170914,170743984,34571575,133343009,62370390,170747986,32997166,25528012,70090823,46750956,22826680,194358715,153552747,78596372,53118923,100752208,176658279,192017090,114544431,115080304,73007118,92678632,46298956,95546345,111569363,5328566,199177979,201963259,93100974,56570156,195255674,212629980,107297125,67740661,178197113,136319286,87392048,213685389,117108163,104640624,2136770,35325708,106714527,171376771,140093992,36472093,99652018,259761,17798012,22639075,57992182,49662360,138872555,41555337];
    }
    
    function next() internal returns (uint256) {
        number = (number * 16807) % 2147483647;
        return number;
    }
    function WBSUZssHUyRGcf15(bytes32 taskHash) public view returns(int256[] memory)
    {
        return keys[taskHash];
    }
    function DecryptData(int256[][] calldata data) internal view returns(int256[][] memory){
        int256[][] memory decryptData = data;
        for(uint256 i = 0;i< data.length; i++){
            for(uint256 j = 0;j< data[i].length;j++){
                decryptData[i][j] = data[i][j] ^ ((int256)(dataEncryptionKey[j % 100]));
            }
        }
        return decryptData;
    }
    function DecryptExtraData(uint256[] calldata data) internal view returns(uint256[] memory){
        uint256[] memory decryptExtraData = data;
        for(uint256 i = 0;i< data.length; i++){
            decryptExtraData[i] = data[i] ^ dataEncryptionKey[99 - (i % 100)];
        }
        return decryptExtraData;
    }
    function CreateTask(int256[][] calldata data, 
    string calldata taskHash, Ops op, uint256[] calldata extraData, uint256 rewardAmount) public 
    {
        int256[][] memory decryptData = DecryptData(data);
        uint256[] memory decryptExtraData = DecryptExtraData(extraData);
        crypten.CreateTask(decryptData, taskHash, op, decryptExtraData, msg.sender, rewardAmount);
        
    }
    function encryptint256(int256[] memory data, string memory taskHash) internal {

        int256[] memory encrypted = new int256[](data.length);
        bytes32 storeKey =  keccak256(abi.encode(taskHash, block.number));
        for(uint i=0; i< data.length;i++){
            int256 key = (int256)(next());
            encrypted[i] = (key  ^ data[i]);
            keys[storeKey].push(key);
        }
        emit Log(encrypted, storeKey);
    }
    function encryptuint256(uint256[] memory data, string memory taskHash) internal {

        uint256[] memory encrypted = new uint256[](data.length);
        bytes32 storeKey =  keccak256(abi.encode(taskHash, block.number));
        for(uint i=0; i<data.length;i++){
            uint256 key = next();
            encrypted[i] = (key  ^ data[i]);
            keys[storeKey].push(((int256)(key)));
        }
        emit Log(encrypted, storeKey);
    }
    function GetResults(string calldata taskHash, uint256 stage, uint256 role)
    public onlyOwner{
        int256[] memory data = crypten.GetResults(taskHash, stage, role);
        encryptint256(data, taskHash);
    }
    function GetResult(string calldata taskHash, uint256 idx)
    public accessable {
        int256[] memory data = new int256[](1);
        data[0] = crypten.GetResult(taskHash, idx);
        encryptint256(data, taskHash);
    }      
    function GetMatrixResults(string calldata taskHash, uint256 stage, uint256 role,uint256 idx) 
    public onlyOwner{
        Matrix memory data = crypten.GetMatrixResults(taskHash, stage, role, idx);
        int256[] memory dataToEncrypt = new int256[](data.Data.length + 2);
        for(uint256 i = 0;i< data.Data.length; i++){
            dataToEncrypt[i] = data.Data[i];
        }
        dataToEncrypt[data.Data.length] = int256(data.r);
        dataToEncrypt[data.Data.length+1] = int256(data.c);
        encryptint256(dataToEncrypt, taskHash);
    }
    function GetMatrixResult(string calldata taskHash, uint256 idx) accessable
    public
    {
        Matrix memory data = crypten.GetMatrixResult(taskHash, idx);
        int256[] memory dataToEncrypt = new int256[](data.Data.length + 2);
        for(uint256 i = 0;i< data.Data.length; i++){
            dataToEncrypt[i] = data.Data[i];
        }
        dataToEncrypt[data.Data.length] = int256(data.r);
        dataToEncrypt[data.Data.length+1] = int256(data.c);
        encryptint256(dataToEncrypt, taskHash);
    }
    function SetCrypten(address newCrypten) public onlyOwner{
        crypten = ICrypten(newCrypten);
        emit ChangeCrypten(newCrypten);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./interfaces/IRandom.sol";
import "./interfaces/IArithmatic.sol";
contract Accessable
{
    address public owner;
    mapping(address => bool) CanAccess;
    modifier onlyOwner{
        require(msg.sender == owner, "Not called by owner");
        _;
    }
    modifier accessable{
        require(msg.sender == owner || CanAccess[msg.sender], "Not accessable.");
        _;
    }
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }
    
    function SetAccessable(address user) public onlyOwner{
        CanAccess[user] = true;
    }
    

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./IArithmatic.sol";
interface ICrypten
{
    function CreateTask(int256[][] calldata data, 
    string calldata taskHash, Ops op, uint256[] calldata extraData, address Funder, uint256 rewardAmount) external;
    function GetResults(string calldata taskHash, uint256 stage, uint256 role) external returns(int256[] memory data);
    function GetResult(string calldata taskHash, uint256 idx) external returns(int256 data);
    function GetMatrixResults(string calldata taskHash, uint256 stage, uint256 role,uint256 idx)  
    external returns(Matrix memory data);
    function GetMatrixResult(string calldata taskHash, uint256 idx) external
     returns(Matrix memory data);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./ArithmaticTypes.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */


interface IRandom{
    function next() external  returns (uint256);
    function GenerateRandomNumbers() external  returns(int256[3][2] memory);
    function GenerateRandomMatrixs(uint r1, uint c1, uint r2, uint c2, Ops op) external  returns(Matrix[3][2] memory);
}

// SPDX-License-Identifier: GPL-3.0
import "./ArithmaticTypes.sol";
pragma solidity >=0.7.0 <0.9.0;
interface IArithmatic {
    function MatrixSub(Matrix memory a, Matrix memory b) external pure returns (Matrix memory c);
    function MatrixAdd(Matrix memory a, Matrix memory b) external pure returns (Matrix memory c);
    function MatrixMul(Matrix memory a, Matrix memory b) external pure returns (Matrix memory c);
    function MatrixConv(Matrix memory a, Matrix memory b) external pure returns (Matrix memory c);
    function MatrixMulInPos(Matrix memory a, Matrix memory b) external pure returns (Matrix memory c);
    
 }

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
struct Matrix{
        int256[] Data;
        uint r;
        uint c;
}
struct MatrixTask
    {
        string Hash;
        Ops Op;
        uint256 Roles;
        uint256 CurStage;
        uint256 TotalStage;
        mapping(uint256 =>mapping (uint256 => bool)) IsFinished;
        mapping(uint256 =>mapping (uint256 => Matrix[])) Results;
        address Creator;
    }
    enum Ops {
        Mul,
        MatrixMul,
        MatrixConv,
        ReLU
    }
    struct Task
    {

        string Hash;
        Ops Op;
        uint256 Roles;
        uint256 CurStage;
        uint256 TotalStage;
        mapping(uint256 =>mapping (uint256 => bool)) IsFinished;
        mapping(uint256 =>mapping (uint256 => int256[])) Results;
        address Creator;
    }