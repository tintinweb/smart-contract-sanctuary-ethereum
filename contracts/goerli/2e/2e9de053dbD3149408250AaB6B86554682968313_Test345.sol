// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";


contract Test345 is KeeperCompatibleInterface{

    string public name = "test345";
    string public symbol = "T345";
    uint256 public totalSupply = 5000;
    uint256 lastTimeStamp;

    address public owner;
    address public admin;

    mapping(address => uint256) public balanceOf;

    uint emitStarted = 0;

    constructor() public {
        owner = msg.sender;
        admin = 0x3bBf8580B386a7903703023F4FF8C3d6aC0654C3;
        lastTimeStamp = block.timestamp;
    }

    //this modifier checks if caller is owner or admin
    modifier onlyAdminOrOwner() {
        require((msg.sender == owner || msg.sender == admin), "Unauthorized access!! Only Admin or Owner can call this Function");
        _;
    }

    //Only admin or owner can transfer liquidity to a address
    function transfer(address recipient, uint256 _amnt) public onlyAdminOrOwner{
        require(totalSupply > _amnt, "No liquidity remained to transfer");
        totalSupply -= _amnt;
        balanceOf[recipient] += _amnt;
    }

    //To check whether an emit transfer is needed or not.
    function checkUpkeep(bytes calldata ) external override returns (bool upkeepNeeded, bytes memory) {
        //this is checking if current timestamp is 5 minutes ahead of lastTimestamp 
        upkeepNeeded = (emitStarted == 1 && (block.timestamp - lastTimeStamp) >= ( 5 * 60 * 1000));
    }

    function performUpkeep(bytes calldata) external override {

        //if upkeep is needed , we will perform following
        require(totalSupply > 5, "Not enough liquidity of tokens remained!!");
        lastTimeStamp = block.timestamp;
        transfer(owner, 5);

        //check again if after first transfer, we are out of balance
        require(totalSupply > 5, "Not enough liquidity of tokens remained!!");
        transfer(admin, 5);
        
    }

    //_action refers to start(1) and stop(0) actions
    function emitTokens(uint _action) public onlyAdminOrOwner{
        if(_action == 0){
            require(emitStarted == 1, "No emit event is runningt to stop");
            emitStarted = 0;
        }else if(_action == 1){
            require(emitStarted == 0, "Emit event is already running!");
            emitStarted = 1;

            //we will start the emit events right after this
            require(totalSupply > 5, "Not enough liquidity of tokens remained!!");
            lastTimeStamp = block.timestamp;
            transfer(owner, 5);
            
            //check again if after first transfer, we are out of balance
            require(totalSupply > 5, "Not enough liquidity of tokens remained!!");
            transfer(admin, 5);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}