// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Example {
    event Foo(string a);

    struct Baz {
        uint test;
        string test2;
    }

    event Bar(Baz a);

    function test() public {
        emit Foo("hello");
    }

    function test2() public {
        Baz memory example = Baz({ test: 69, test2: "hello" });
        emit Bar(example);
    }
}