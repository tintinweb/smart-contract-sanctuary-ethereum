/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract PredictionRecorder {

    struct Prediction {
        address targetOracle;
        uint targetTime;
        uint creationTime;
        int predictedValue;
        address predictionAddress;
        string predictionAuthor;
        string predictionComment;
    }

    address private oracleAddress;
    mapping (address => Prediction[]) private predictions;

    constructor(address _oracleAddress) {
        oracleAddress = _oracleAddress;
    }

    /**
     * Make a prediction and keep its record in this contract.
     */
    function makePrediction(
        uint _targetTime,
        int _predictedValue,
        string memory _predictionAuthor,
        string memory _predictionComment
    ) external {
        require(block.timestamp < _targetTime, "Cannot predict the past.");

        predictions[msg.sender].push(Prediction({
            targetOracle: oracleAddress,
            targetTime: _targetTime,
            creationTime: block.timestamp,
            predictedValue: _predictedValue,
            predictionAddress: msg.sender,
            predictionAuthor: _predictionAuthor,
            predictionComment: _predictionComment
        }));
    }

    /**
     * View all the predictions made by the sender.
     */
    function viewOwnPrediction() public view returns (Prediction[] memory) {
        return predictions[msg.sender];
    }

    /**
     * View the predictions made by an address.
     * Limited to predictions whose target time has passed.
     */
    function viewOthersPrediction(
        address _predictionAddress
    ) public view returns (Prediction[] memory) {
        
        /* Fetch stored predictions and find indices of those that belong in the past*/
        Prediction[] memory storedPredictions = predictions[_predictionAddress];
        uint[] memory pastIndices = new uint[](storedPredictions.length);
        uint numPastIndices = 0;
        uint currentTimeStamp = block.timestamp;

        /* Collect past prediction indices*/
        for (uint i = 0; i < storedPredictions.length; i++) {
            if (storedPredictions[i].targetTime < currentTimeStamp) {
                pastIndices[numPastIndices] = i;
                numPastIndices++;
            }
        }

        /* Build return array */
        Prediction[] memory pastPredictions = new Prediction[](numPastIndices);
        for (uint i = 0; i < numPastIndices; i++) {
            pastPredictions[i] = storedPredictions[pastIndices[i]];
        }

        return pastPredictions;
    }

    /**
     * View the address of the oracle for sanity check.
     */
    function viewOracle() public view returns (address) {
        return oracleAddress;
    }
}