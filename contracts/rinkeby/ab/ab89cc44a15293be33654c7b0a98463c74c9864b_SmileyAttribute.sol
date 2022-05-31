/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISmileyAttribute {
    //returns name of the attributte
    function getAttributeName() external view returns (string memory);

    //retrives name of i-th value
    function getValueName(uint80 index) external view returns (string memory);

    //returns SVG string of i-th value
    function getSVGData(uint80 index) external view returns (string memory);

    //"randomly" picks value taking weights into consideration
    function pickRandomValue() external view returns (uint80 value);

    //return how much points certain value worth
    function getPoints(uint80 index) external view returns (uint256 value);
}

contract SmileyAttribute is ISmileyAttribute {
    //name of attribute
    string private attributeName;
    //name of attribute values
    string[] private values;
    //SVG string for each value
    string[] private SVGData;
    //proabbility that values will be picked
    uint128[] private weights;
    //how much points each value worths
    uint256[] private points;
    //sum of all weights (to avoid calculating it every time pickRandomValue is called)
    uint256 private weightsSum;

    constructor(
        string memory _attributeName,
        string[] memory _values,
        string[] memory _SVGData,
        uint128[] memory _weights,
        uint256[] memory _points
    ) {
        require(_weights.length == _SVGData.length, "Length mismatch");
        require(_weights.length == _points.length, "Length mismatch");

        attributeName = _attributeName;
        SVGData = _SVGData;
        values = _values;
        points = _points;
        weights = _weights;

        for (uint256 i = 0; i < weights.length; i++) {
            weightsSum += weights[i];
        }
    }

    function getAttributeName() external view override returns (string memory) {
        return attributeName;
    }

    function getValueName(uint80 index)
        external
        view
        override
        returns (string memory)
    {
        return values[index];
    }

    function getSVGData(uint80 index)
        external
        view
        override
        returns (string memory)
    {
        return SVGData[index];
    }

    function getPoints(uint80 index)
        external
        view
        override
        returns (uint256 value)
    {
        return points[index];
    }

    function pickRandomValue() external view override returns (uint80 value) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(attributeName, blockhash(block.number - 1))
            )
        );
        uint256 randomNumber = seed % weightsSum;

        uint256 previousSum = 0;
        uint80 pick = 0;

        for (uint80 i = 0; i < weights.length; i++) {
            if (randomNumber < previousSum + weights[i]) {
                pick = i;
                break;
            }
            previousSum += weights[i];
        }

        return pick;
    }
}