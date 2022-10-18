// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./interfaces/IRandom.sol";
import "./interfaces/IArithmatic.sol";
import "./Accessable.sol";
import "./interfaces/IFairlaunch.sol";
contract Crypten is Accessable
{
    event Read(address reader);
    mapping(string => Task) Tasks;
    mapping(string => Ops) TaskType;
    mapping(string => MatrixTask) MatrixTasks;
    mapping(string => bool) IsAdded;
    uint256 public RewardPerStage;
    IRandom public Random;
    IArithmatic public Arithmatic;
    IFairlaunch public Fairlaunch;
    function CreateTask(int256[][] calldata data, 
    string calldata taskHash, Ops op, uint256[] calldata extraData, 
    address Funder, uint256 TreasuryAmount) public accessable
    {
        require(!IsAdded[taskHash], "Task already added");
        if(op == Ops.Mul){
            Task storage task = Tasks[taskHash];
            task.Hash = taskHash;
            task.Roles = 2;
            task.Op = op;
            task.Creator = msg.sender;
            int256[3][2] memory abc = Random.GenerateRandomNumbers();
            
            for(uint i = 0;i< 2; i++){
                task.Results[0][i] = data[i];
                for(uint j = 0; j < 3; j++){
                    task.Results[0][i].push(abc[i][j]);
                }
            }
            task.CurStage = 1;
            task.TotalStage = 2;
        }
        else{
            MatrixTask storage task = MatrixTasks[taskHash];
            task.Hash = taskHash;
            task.Roles = 2;
            task.Op = op;
            task.Creator = msg.sender;
            Matrix[3][2] memory abc = Random.GenerateRandomMatrixs(extraData[0], extraData[1],
            extraData[2], extraData[3], op);
            for(uint i = 0;i< 2; i++){
                task.Results[0][i].push(Matrix(data[i*2], extraData[0], extraData[1]));
                task.Results[0][i].push(Matrix(data[i*2 + 1], extraData[2], extraData[3]));
                for(uint j = 0; j < 3; j++){
                    task.Results[0][i].push(abc[i][j]);
                }
            }
            task.CurStage = 1;
            task.TotalStage = 2;
        }
        TaskType[taskHash] = op;
        IsAdded[taskHash] = true;
        Fairlaunch.TaskCreated(taskHash, Funder, TreasuryAmount);
    }
    function ExecuteTask(uint256 role, string calldata taskHash) public
    {
        require(IsAdded[taskHash], "No such task");
        Ops op = TaskType[taskHash];
        if(op == Ops.Mul){
            Mul(role, taskHash);
        }
        else{
            ExecuteMatrixTask(role, taskHash);
        }
        Fairlaunch.TaskStageFinished(taskHash, msg.sender, RewardPerStage);
    }
    function IsTaskAvaiable(uint256 role, string calldata taskHash) public view returns(bool){
        require(IsAdded[taskHash], "No such task");
        Ops op = TaskType[taskHash];
        if(op == Ops.Mul){
            Task storage task = Tasks[taskHash];
            return task.CurStage < task.TotalStage
            &&(!task.IsFinished[task.CurStage][role] || task.IsFinished[task.CurStage][1 - role]);
        }
        else{
            MatrixTask storage task = MatrixTasks[taskHash];
            return task.CurStage < task.TotalStage
            &&(!task.IsFinished[task.CurStage][role] || task.IsFinished[task.CurStage][1 - role]);
        }

    }
    function GetResults(string calldata taskHash, uint256 stage, uint256 role) accessable 
    public returns(int256[] memory data){
        Task storage task = Tasks[taskHash];
        require(msg.sender == task.Creator, "Not creator. Retrieve failed.");
        emit Read(msg.sender);
        return task.Results[stage][role];
    }
    function GetResult(string calldata taskHash, uint256 idx) accessable 
    public returns(int256 data){
        Task storage task = Tasks[taskHash];
        require(msg.sender == task.Creator, "Not creator. Retrieve failed.");
        emit Read(msg.sender);
        return task.Results[task.TotalStage][0][idx] + task.Results[task.TotalStage][1][idx];
    }
    function GetMatrixResults(string calldata taskHash, uint256 stage, uint256 role,uint256 idx) accessable  
    public returns(Matrix memory data){
        MatrixTask storage task = MatrixTasks[taskHash];
        require(msg.sender == task.Creator, "Not creator. Retrieve failed.");
        emit Read(msg.sender);
        return task.Results[stage][role][idx];
    }
    function GetMatrixResult(string calldata taskHash, uint256 idx) accessable
    public returns(Matrix memory data)
    {
        MatrixTask storage task = MatrixTasks[taskHash];
        require(msg.sender == task.Creator, "Not creator. Retrieve failed.");
        emit Read(msg.sender);
        return Arithmatic.MatrixAdd(task.Results[task.TotalStage][0][idx],
            task.Results[task.TotalStage][1][idx]);
    }
    function Mul(uint256 role, string calldata taskHash) internal
    {
        require(IsAdded[taskHash], "No such task");
        Task storage task = Tasks[taskHash];
        require(task.CurStage > 0, "Not initialze correctly");
        require(task.Op == Ops.Mul, "Not Mul Task");
        if(task.IsFinished[task.CurStage][role]){
            require(task.IsFinished[task.CurStage][1 - role], "Partner not finished");
            require(task.CurStage < task.TotalStage, "Task already done.");
            task.CurStage += 1;
        }
        if(task.CurStage == 1){
            int256 e = task.Results[0][role][0] - task.Results[0][role][2];
            int256 f = task.Results[0][role][1] - task.Results[0][role][3];
            task.Results[1][role] = [e,f];
            task.IsFinished[1][role] = true;
            return;
        }
        if(task.CurStage == 2){
            int256 e = task.Results[1][role][0] + task.Results[1][1-role][0];
            int256 f = task.Results[1][role][1] + task.Results[1][1-role][1];
            if(role == 0){
                int256 z = f * task.Results[0][role][2] +
                 e * task.Results[0][role][3] + task.Results[0][role][4];
                task.Results[task.CurStage][role].push(z);
            }
            else{
                int256 z = e * f + f * task.Results[0][role][2] +
                 e * task.Results[0][role][3] + task.Results[0][role][4];
                task.Results[task.CurStage][role].push(z);
            }
            task.IsFinished[task.CurStage][role] = true;
        }
    }
    function ExecuteMatrixTask(uint256 role, string calldata taskHash) internal
    {
        require(IsAdded[taskHash], "No such task");
        MatrixTask storage task = MatrixTasks[taskHash];
        require(task.CurStage > 0, "Not initialze correctly");
        if(task.IsFinished[task.CurStage][role]){
            require(task.IsFinished[task.CurStage][1 - role], "Partner not finished");
            require(task.CurStage < task.TotalStage, "Task already done.");
            task.CurStage += 1;
        }
        if(task.CurStage == 1){
            MatrixStepOne(task, role);
            return;
        }
        if(task.CurStage == 2){
            MatrixStepTwo(task, role);
            return;
        }
    }
    
    function MatrixStepOne(MatrixTask storage task, uint role) internal{
        task.Results[1][role].push(Arithmatic.MatrixSub(task.Results[0][role][0], task.Results[0][role][2]));
        task.Results[1][role].push(Arithmatic.MatrixSub(task.Results[0][role][1], task.Results[0][role][3]));
        task.IsFinished[1][role] = true;
    }
    function MatrixStepTwo(MatrixTask storage task, uint role) internal{
        Matrix memory p;
        Matrix memory q;
        {
            p = Arithmatic.MatrixAdd(task.Results[1][0][0], task.Results[1][1][0]);
            q = Arithmatic.MatrixAdd(task.Results[1][0][1], task.Results[1][1][1]);
        }
        Matrix memory u = task.Results[0][role][2];
        Matrix memory v = task.Results[0][role][3];
        Matrix memory z = task.Results[0][role][4];
        if(role == 0){
            Matrix memory res = Arithmatic.MatrixAdd(
                Arithmatic.MatrixAdd(MatrixStepTwoInner(u,q,task.Op),
                MatrixStepTwoInner(p,v,task.Op)), z);
            task.Results[task.CurStage][role].push(res);
        }
        else{
            Matrix memory pv = MatrixStepTwoInner(p,v, task.Op);
            Matrix memory uq = MatrixStepTwoInner(u,q, task.Op);
            Matrix memory res = 
            Arithmatic.MatrixAdd(MatrixStepTwoInner(p,q, task.Op), Arithmatic.MatrixAdd(
                Arithmatic.MatrixAdd(uq, pv), z));
            task.Results[task.CurStage][role].push(res);
        }
    }
    function MatrixStepTwoInner(Matrix memory x, Matrix memory y, Ops op) internal view returns(Matrix memory){
        if(op == Ops.ReLU){
            return Arithmatic.MatrixMulInPos(x,y);
        }
        else if(op == Ops.MatrixConv){
            return Arithmatic.MatrixConv(x,y);
        }
        else{
            return Arithmatic.MatrixMul(x,y);
        }
    }
    function SetParams(address _random, address _arithmatic, address _fairlaunch, uint256 reward) public onlyOwner{
        Random = IRandom(_random);
        Arithmatic = IArithmatic(_arithmatic);
        Fairlaunch = IFairlaunch(_fairlaunch);
        RewardPerStage = reward;
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

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

interface IFairlaunch
{
    function TaskCreated(string calldata taskHash,address creator, uint256 treasuryAmount) external;
    function TaskStageFinished(string calldata taskHash, address executor,
        uint256 addShare) external;
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