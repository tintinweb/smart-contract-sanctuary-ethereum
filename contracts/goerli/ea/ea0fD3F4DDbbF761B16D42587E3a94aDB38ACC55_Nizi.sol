/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

contract Nizi {

    uint number_of_contents = 0;

    // ２次、1次は関係なし コンテンツIDから作者のアドレスを返す
    mapping(uint => address) private _authors;
    // 権利があるかどうかのboolを返す
    mapping(uint => bool) private _rights;
    // 二次創作をする権利取得時のロイヤリティ（ロイヤリティという言葉が正しいかどうかは疑問...）
    mapping(uint => uint) private _royalties;
    // 親作品を返す
    mapping(uint => uint) private _parents;
    // contents list
    mapping(address => mapping(uint => uint)) _contents_lists;
    // contents list
    mapping(address => uint) _total_content_numbers;

    event RegisterOriginal(address indexed _from, uint royalty);
    event RegisterSecondary(address indexed _from, uint parent_id);

    /*
        一次創作者の作品登録
        ロイヤリティを設定できる。0も可能
        また、ロイヤリティは後からでも設定できる(setRoyalty(uint)をつかう)
        @return contentId
    */
    function registerOriginal(uint _royalty) public returns (uint) {
        number_of_contents += 1;
        _authors[number_of_contents] = msg.sender;
        _royalties[number_of_contents] = _royalty;
        _contents_lists[msg.sender][_total_content_numbers[msg.sender]] = number_of_contents;
        _total_content_numbers[msg.sender] += 1;

        emit RegisterOriginal(msg.sender, _royalty);
        return number_of_contents;
    }

    /*
        二次創作者の作品登録
        ロイヤリティが設定されていたら支払いを行う
        @param _parent_id 親のコンテンツID
        @return contentId
    */
    function registerSecondary(uint _parent_id) public payable returns (uint) {
        // ロイヤリティと同じ金額を入れないとリバート
        require(msg.value == _royalties[_parent_id]);
        require(number_of_contents >= _parent_id && _parent_id != 0);

        payable(_authors[_parent_id]).transfer(msg.value);

        number_of_contents += 1;
        _authors[number_of_contents] = msg.sender;
        _rights[number_of_contents] = true;
        _parents[number_of_contents] = _parent_id;

        _contents_lists[msg.sender][_total_content_numbers[msg.sender]] = number_of_contents;
        _total_content_numbers[msg.sender] += 1;

        emit RegisterSecondary(msg.sender, _parent_id);
        return number_of_contents;
    }

    // 一次創作者が権利を剥奪する
    function deprive(uint _parent_id, uint _child_id) public {
        require(_parents[_child_id] == _parent_id);
        require(msg.sender == _authors[_parent_id], "you are not the original owner");
        _rights[_child_id] = false;
    }

    // 一次創作者が権利を再び与える（二次創作品の問題点が修正された場合など）
    function recover(uint _parent_id, uint _child_id) public {
        require(_parents[_child_id] == _parent_id);
        require(msg.sender == _authors[_parent_id]);
        _rights[_child_id] = true;
    }

    /*
        ロイヤリティを設定する
        @return void
    */
    function setRoyalty(uint _content_id, uint royalty) public {
        require(msg.sender == _authors[_content_id]);
        _royalties[_content_id] = royalty;
    }

    function checkRight(uint _content_id) public view returns(bool) {
        // 親が設定されていないものは一次作品なのでtrueを返す
        if(_parents[_content_id] == 0) return true;
        return _rights[_content_id];
    }

    function getAuthor(uint _content_id) public view returns(address) {
        return _authors[_content_id];
    }

    function getNumberOfContents() public view returns(uint) {
        return number_of_contents;
    }

    function getContentsList(address author) public view returns(uint[] memory) {
        uint[] memory ret = new uint[](_total_content_numbers[author]);
        for (uint i = 0; i < _total_content_numbers[author]; i++) {
            ret[i] = _contents_lists[author][i];
        }
        return ret;
    }

    function getRoyalty(uint _content_id) public view returns(uint) {
        return _royalties[_content_id];
    }

    function getParent(uint child_id) public view returns(uint) {
        return _parents[child_id];
    }
}