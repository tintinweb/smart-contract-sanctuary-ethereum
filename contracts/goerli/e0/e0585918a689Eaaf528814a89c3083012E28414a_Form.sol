// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Form{
    uint32 public nonce = 0;

    struct Record{
        string CID;
        uint32 form_id;
        address responder;
    }

    Record record;

    struct FormMetaData{
        string CID; 
        uint32 form_id;
        address creator;
    }

    Form form;

    mapping(uint32 => Record[])  FormResponses;
    mapping(address => Record[]) UserResponses;
    mapping(uint32 => FormMetaData) public MetaData;
    mapping(address => uint32[]) public FormCreators;
    mapping(address => mapping(uint32 => bool)) public IsFormFilled;

    function createTheForm(string memory _formData) external{
        FormMetaData memory form_meta_data = FormMetaData(
           _formData , nonce+1 , msg.sender
        );
        MetaData[nonce+1] = form_meta_data;
        FormCreators[msg.sender].push(nonce+1);
        nonce += 1;
    }

    function fillForm(string memory _formData, uint32 _formId) external{
        require(!IsFormFilled[msg.sender][_formId]);
        Record memory record_data = Record(
            _formData, _formId, msg.sender
        );
        FormResponses[_formId].push(record_data);
        UserResponses[msg.sender].push(record_data);
        IsFormFilled[msg.sender][_formId] = true;
    }

    function formResponses(uint32 _formId) public view returns(Record[] memory){
        return FormResponses[_formId];
    }

    function userResponses() public view returns(Record[] memory){
        return UserResponses[msg.sender];
    }

}