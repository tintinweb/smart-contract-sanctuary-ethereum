// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./IPioneers.sol";


pragma solidity >=0.8.8 < 0.9.0;

contract PioneersTrails is KeeperCompatibleInterface{

    uint constant INCONVENIENCE_BLOCK_INTERVAL = 255;

    mapping(uint8 => bytes12) public trailToEncodedInconveniences;

    // Errors def
    error PIONEERS_EmptyTrail();
    error PIONEERS_NoUpkeepNeeded();

    address pioneers;
    
    constructor(){
        pioneers = msg.sender;
    }

    function setPioneers(address _pioneers) public{
        require(msg.sender == pioneers,"sender");
        pioneers = _pioneers;
    }

    /** Convert given _baseTrailId to an ancestor trail ID based on current stage. */
    function getTrailIdByStage(uint8 _baseTrailId,bool debug) public view returns(uint8 _updatedTrailId){
        

        if (debug){
            return _baseTrailId;
        }
        else{
            if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey1)
                return _baseTrailId;
            else if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey2)
                return (_baseTrailId - 1) / 2;
            else if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey3) 
            {
                uint8 parent = (_baseTrailId - 1) / 2;
                return (parent - 1) / 2;
            }
            else if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey4)
                return 0;
        }

    }

    // //DEBUG PURPOSES OVERRIDE
    // function stage() public pure override returns(Stage){
    //     return Stage.Journey1;
    // }

    function getEncodedInconveniencesByTrail(uint8 _baseTrailId) public view returns(bytes12){
        return trailToEncodedInconveniences[getTrailIdByStage(_baseTrailId,false)];
    }

    /** Decode bytes-written inconveniences into array of string (single-char). */
    function getDecodedInconveniencesByTrail(uint8 _baseTrailId) public view returns (string[] memory _decodedInconveniences,uint256 _size){
        string[] memory inconveniences = new string[](12);
        
        uint8 updatedTrailId = getTrailIdByStage(_baseTrailId,false);

        bytes12 inconveniencesBytes = trailToEncodedInconveniences[updatedTrailId];

        if(inconveniencesBytes.length == 0)
            revert PIONEERS_EmptyTrail();

        uint size = 0;

        for(uint i = 0 ; i < 12; i++)
            if(inconveniencesBytes[i] != 0){
                inconveniences[i] = string(
                 abi.encodePacked( inconveniencesBytes[i] )
                );
                size++;
            }

        return (inconveniences,size);
    }

    /** Get the current active inconvenience for the given trail and hash. */
    function getCurrentTrailInconvenience(uint8 _baseTrailId, int _currentHash) public view returns (string memory _inconvenience){
        string[] memory allTrailInconveniences;
        (allTrailInconveniences,) = getDecodedInconveniencesByTrail(_baseTrailId);

        int validLength = 0;

        for(uint i = 0; i <= allTrailInconveniences.length && bytes(allTrailInconveniences[i]).length != 0 ; i++)
            validLength++;

        return allTrailInconveniences[ uint(_currentHash % validLength) ];
    }

    /** Debug function for pseudo-random number. */
    function getRandomNumber(bool _isDebug) public view returns (uint _rand){
        if(!_isDebug){
            uint eliminationBlock = block.number - (block.number % INCONVENIENCE_BLOCK_INTERVAL) + 1;
            return uint(blockhash(eliminationBlock))%uint(type(int).max);
        }
        else
            return uint(keccak256(abi.encodePacked(
                block.timestamp, 
                blockhash(block.number)
            )));
    }

    function removeByteFromBytes16(bytes16 data, uint index) public pure returns(bytes16){
        bytes memory tmp = new bytes(16);
        uint found = 0;
        for(uint i = 0; i < 16; i++){
            if(i != index){
                tmp[i-found] = data[i];
            }
            else found++;
        }
        return bytes16(abi.encodePacked(tmp));
    }

    /** When a stage is completed, this function calculates inconveniences for new trails. This must reward the caller.  
    The number generation seed must be obtained from Chainlink VRF (or blockhash).
    In the current version, the generation is made by block.timestamp 
    CURRENTLY IT'S PUBLIC AND IT'S A SECURITY PROBLEM. */

    function generateInconveniencesForNextTrails(uint8 nextStage) public{
        
        // pidyjmcwhxbrq
        bytes16 allInconveniences = "pidyjmcwhxbrq";

        IPioneers.Stage _nextStage = IPioneers.Stage(nextStage);

        if(_nextStage == IPioneers.Stage.Journey1){
            if(trailToEncodedInconveniences[7].length == 0)
                for(uint i = 7; i <= 14; i++){
                    bytes memory temp = new bytes(12);
                    bytes16 availableInconveniences = allInconveniences;
                    uint removedInconveniences = 0;
                    for(uint j = 0; j < 3; j++){
                        uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                        temp[j] = availableInconveniences[rand];
                        removedInconveniences++;
                        availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                    }
                    trailToEncodedInconveniences[uint8(i)] = bytes12(abi.encodePacked(temp[0],temp[1],temp[2]));
                }
        }
                
        else if(_nextStage == IPioneers.Stage.Journey2){
            if(trailToEncodedInconveniences[3].length == 0)
                for(uint i = 3; i <= 6; i++){
                    bytes memory temp = new bytes(12);
                    bytes16 availableInconveniences = allInconveniences;
                    uint removedInconveniences = 0;
                    for(uint j = 0; j < 6; j++){
                        uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                        temp[j] = availableInconveniences[rand];
                        removedInconveniences++;
                        availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                    }

                    trailToEncodedInconveniences[uint8(i)] = bytes12(temp);
                }
        }
            
        else if(_nextStage == IPioneers.Stage.Journey3)
        {
            if(trailToEncodedInconveniences[1].length == 0)
                for(uint i = 1; i <= 2; i++){
                    bytes memory temp = new bytes(12);
                    bytes16 availableInconveniences = allInconveniences;
                    uint removedInconveniences = 0;
                    for(uint j = 0; j < 9; j++){
                        uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                        temp[j] = availableInconveniences[rand];
                        removedInconveniences++;
                        availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                    }

                    trailToEncodedInconveniences[uint8(i)] = bytes12(temp);
                }
        }
        else if(_nextStage == IPioneers.Stage.Journey4){
            if(trailToEncodedInconveniences[0].length == 0)
            {
                bytes memory temp = new bytes(12);
                bytes16 availableInconveniences = allInconveniences;
                uint removedInconveniences = 0;
            
                for(uint j = 0; j < 12; j++){
                    uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                    temp[j] = availableInconveniences[rand];
                    removedInconveniences++;
                    availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                }
                trailToEncodedInconveniences[0] = bytes12(temp);
            }
        }
            
    } 

    function currentInconveniences(uint8 _baseTrailId) public view returns (string memory _pickedLetter, string memory _pickedInconvenience, bytes32 _inconvenienceId)
    {       
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWYZ";

        uint eliminationBlock = block.number - (block.number % INCONVENIENCE_BLOCK_INTERVAL) + 1;
        int hash = int(uint(blockhash(eliminationBlock))%uint( type(int).max) );
        // int hash = int(getRandomNumber(true));

        uint rand = uint(hash) % 25;
        string memory pickedLetter = string( abi.encodePacked(alphabet[rand]) );

        uint256 size;
        string[] memory inconveniences;
        (inconveniences, size) = getDecodedInconveniencesByTrail(_baseTrailId);
        rand = uint(hash) % size;
        string memory pickedInconvenience = inconveniences[rand];

        return(pickedLetter, pickedInconvenience, blockhash(eliminationBlock));
    }

    

    //===Chainlink Keepers Implementation

    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        IPioneers.Stage _stage = IPioneers(pioneers).stage();
        bool trailInconveniencesNotGenerated = false;
        
        if(_stage == IPioneers.Stage.Journey1)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(7).length == 0;
        else if(_stage == IPioneers.Stage.Journey2)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(3).length == 0;
        else if(_stage == IPioneers.Stage.Journey3)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(1).length == 0;
        else if(_stage == IPioneers.Stage.Journey4)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(0).length == 0;

        upkeepNeeded = trailInconveniencesNotGenerated;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded,) = checkUpkeep("");

        if(!upkeepNeeded)
            revert PIONEERS_NoUpkeepNeeded();
        else
        {
            generateInconveniencesForNextTrails(uint8(IPioneers(pioneers).stage()));
        }
    }

    //==End Chainlink Keepers
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPioneers {

    enum Stage {Initial, Minting, Journey1, Journey2, Journey3, Journey4, Destination }

    function stage() external view returns(Stage);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

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
  function performUpkeep(bytes calldata performData) external;
}