// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4 <0.8.0;
pragma experimental ABIEncoderV2;

contract Product {
    string public productName;
    uint256 public productId;
    address public manufacturer;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public number;
    string public unit;
    Operation[] public operationList;

    struct SensorData {
        string dataType;
        string startTime;
        string endTime;
        string macAddress;
        string[] data;
    }

    struct Media {
        string url;
        string md5;
    }

    struct Operation {
        string operationName;
        uint256 inputNumber;
        uint256 outputNumber;
        address[] sourceList;
        uint256 startTime;
        uint256 endTime;
        SensorData[] sensorList;
        Media[] proofs;
    }

    modifier onlyManufacurer() {
        require(msg.sender == manufacturer, "Address is not a manufacturer");
        _;
    }

    event InitEvent(
        string productName,
        uint256 indexed productId,
        address manufacturer,
        uint256 startTime,
        uint256 endTime,
        uint256 number,
        string unit
    );
    event AddOperationEvent(
        string operationName,
        uint256 inputNumber,
        uint256 outputNumber,
        uint256 indexed startTime,
        uint256 indexed endTime
    );

    constructor(
        string memory _productName,
        uint256 _productId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _number,
        string memory _unit
    ) {
        productName = _productName;
        productId = _productId;
        manufacturer = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
        number = _number;
        unit = _unit;

        emit InitEvent(
            _productName,
            _productId,
            manufacturer,
            _startTime,
            _endTime,
            _number,
            _unit
        );
    }

    function addOperation(
        string calldata _operationName,
        uint256 _inputNumber,
        uint256 _outputNumber,
        address[] calldata _sourceList,
        uint256 _startTime,
        uint256 _endTime
    )
        public
        // SensorData[] calldata _sensorList,
        // Media[] calldata _proofs
        onlyManufacurer
    {
        require(
            (number + _inputNumber) >= _outputNumber,
            "Insufficient number to operate"
        );
        number = number + _inputNumber - _outputNumber;
        endTime = _endTime;

        Operation storage _op;
        _op.operationName = _operationName;
        _op.inputNumber = _inputNumber;
        _op.outputNumber = _outputNumber;
        _op.startTime = _startTime;
        for (uint256 i = 0; i < _sourceList.length; i++) {
            _op.sourceList.push(_sourceList[i]);
        }
        // for (uint256 i = 0; i < _sensorList.length; i++) {
        //     _op.sensorList.push(_sensorList[i]);
        // }
        // for (uint256 i = 0; i < _proofs.length; i++) {
        //     _op.proofs.push(_proofs[i]);
        // }
        // SensorData[] storage _data;
        // for (uint256 i = 0; i < _sensorList.length; i++) {
        //     SensorData storage _tmpData;
        //     _tmpData.dataType = _sensorList[i].dataType;
        //     _tmpData.macAddress = _sensorList[i].macAddress;
        //     _tmpData.startTime = _sensorList[i].startTime;
        //     _tmpData.endTime = _sensorList[i].endTime;
        //     for (uint256 j = 0; j < _sensorList[i].data.length; j++) {
        //         _tmpData.data.push(_sensorList[i].data[j]);
        //     }
        //     _data.push(_tmpData);
        // }
        // _op.sensorList = _data;

        operationList.push(_op);

        emit AddOperationEvent(
            _operationName,
            _inputNumber,
            _outputNumber,
            _startTime,
            _endTime
        );
    }
}