/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BabyBackgrounds {
    string constant private _backgroundPrefix = "iVBORw0KGgoAAAANSUhEUgAAACIAAAAiBAMAAADIaRbxAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAZdEVYdFNvZnR3YXJlAEFkb2JlIEltYWdlUmVhZHlxyWU8AAAAG1BMVE";
    function B_Background(uint32 traitId_) public pure returns (string[2] memory) {
        if (traitId_ == 0 ) return ["b1",                   string(abi.encodePacked(_backgroundPrefix, "Xl/anY+ofm+7Tg/J7p+Mbc+pXo+bzT+3rU/3Cvqk7OAAAAKUlEQVQoz2PsYEADTAzkiLC8p445jIJUco8Llcy5Rx1zqAUYlYZe+AAAg8EEMkrzZzAAAAAASUVORK5CYII="))];
        if (traitId_ == 1 ) return ["b2",                   string(abi.encodePacked(_backgroundPrefix, "X6/an1+of4+7T4/J72+Mb2+pX3+bz0+3r4/3A+w8iCAAAAKUlEQVQoz2PsYEADTAzkiLC8p445jIJUco8Llcy5Rx1zqAUYlYZe+AAAg8EEMkrzZzAAAAAASUVORK5CYII="))];
        if (traitId_ == 2 ) return ["b3",                   string(abi.encodePacked(_backgroundPrefix, "X64Yf567z65JX77bT74Xr966n47cb86J7/4XDFu5TpAAAAKUlEQVQoz2PsYEADTAzkiDC6UMccagFGJeq4hyWUSubcG1zmMArSL3wAQ1MDpj7Y1FEAAAAASUVORK5CYII="))];
        if (traitId_ == 3 ) return ["b4",                   string(abi.encodePacked(_backgroundPrefix, "X6xYf/vnD44cb727T6y5X91qn53Lz80Z77wXqHV10dAAAAK0lEQVQoz2MUZEADTAzkiLCUU8ccagFGFyr5y5hK5twbZOZQyV+MSoTVAACqmQNUiAuDIwAAAABJRU5ErkJggg=="))];
        if (traitId_ == 4 ) return ["b5",                   string(abi.encodePacked(_backgroundPrefix, "X7ybT6qYf7oHr5zbz6spX9wan/mnD8up741Mb6Ej5IAAAAKklEQVQoz2NMY0ADTAzkiDAqUckcQeqYw2I8yMy5Rx1zqAUYqeWvUMJqADZEAqbiCFdLAAAAAElFTkSuQmCC"))];
        if (traitId_ == 5 ) return ["b6",                   string(abi.encodePacked(_backgroundPrefix, "X/dnD9rKn4yMb6jIf6mZX7gHr8op77t7T5vryOgBnpAAAALElEQVQoz2NgoA5gDEUXYWIgR4TlHpXMEaSSOUrUMYeRWu5JG1zhw0hE+AAAPRECVOf3vzEAAAAASUVORK5CYII="))];
        if (traitId_ == 6 ) return ["b7",                   string(abi.encodePacked(_backgroundPrefix, "X8nrH4xtD6lar5vMn7epT7tML/cI39qbv6h57liNynAAAALElEQVQoz2NMY0ADTAzkiLDco5I5LtQxh1GJOuZQCzCWD7JwppI5jIKE1QAAOIUEL3/2TYEAAAAASUVORK5CYII="))];
        if (traitId_ == 7 ) return ["b8",                   string(abi.encodePacked(_backgroundPrefix, "X7erT9qdD8nsn4xt37tNT6lcP6h7v/cLH5vNiwiCG3AAAALklEQVQoz2MsZ0ADTAzkiFALMKZRxz0s76ljDqMSlcwRpJK/jKlkjguV/EWEewAOewLnUIbk2gAAAABJRU5ErkJggg=="))];
        if (traitId_ == 8 ) return ["b9",                   string(abi.encodePacked(_backgroundPrefix, "X9qeX/cNT6ldz8nuD7etP4xun7tOb5vOj6h9guMJtFAAAALElEQVQoz2MUZEADTAzkiLAYU8kcF+qYw6hEJfdQKXyoBRjTBpe/WO4RVgMAHLoCVGetJ3oAAAAASUVORK5CYII="))];
        if (traitId_ == 9 ) return ["b10",                  string(abi.encodePacked(_backgroundPrefix, "X6h/X7evT5vPf/cPj9qfr6lfb8nvj4xvb7tPiHd1ddAAAAL0lEQVQoz2M0ZkADTAzkiDAKUsccagHGUOq4h4VK/mK5RyVzXKgUX0pUcg8R4QwAoUcChP8pB6UAAAAASUVORK5CYII="))];
        if (traitId_ == 10) return ["b11",                  string(abi.encodePacked(_backgroundPrefix, "Xhh/rtxvjrqf3ttPvklfronvzhevvhcP/rvPmOWIajAAAALElEQVQoz2MsZ0ADTAzkiLC8p4451AKMLlTylyB1zGFUGlzuYQmlkr+IcA8AMSAClVg4lNEAAAAASUVORK5CYII="))];
        if (traitId_ == 11) return ["b12",                  string(abi.encodePacked(_backgroundPrefix, "XFh/rhxvjWqf3btPvLlfrRnvzBevu+cP/cvPnqX8JlAAAALElEQVQoz2MsZ0ADTAzkiLC8p4451AKMLlTylyB1zGFUGlzuYQmlkr+IcA8AMSAClVg4lNEAAAAASUVORK5CYII="))];
        if (traitId_ == 12) return ["b13",                  string(abi.encodePacked(_backgroundPrefix, "Wph/rUxvjBqf3JtPuylfq6nvygevuacP/NvPnUE0VAAAAALElEQVQoz2MsZ0ADTAzkiLC8p4451AKMLlTylyB1zGFUGlzuYQmlkr+IcA8AMSAClVg4lNEAAAAASUVORK5CYII="))];
        if (traitId_ == 13) return ["b14",                  string(abi.encodePacked(_backgroundPrefix, "WMh/rIxvisqf23tPuZlfqinvyAevu+vPl2cP+0qm7oAAAALElEQVQoz2PsYEADTAzkiLDco4451AKMLlTylyB1zGFUGlzuYaFS+DAS4R4ALs0ChIFMRf8AAAAASUVORK5CYII="))];
        if (traitId_ == 14) return ["b15",                  string(abi.encodePacked(_backgroundPrefix, "WHnvq8yfmpu/2Vqvpwjf96lPuesfzG0Pi0wvvbLpFHAAAAK0lEQVQoz2N0YUADTAzkiLAIUsccagFGYyr5i0rmMCpRyT1pVHKPIP3cAwAeVAH7ZnLzqQAAAABJRU5ErkJggg=="))];
        if (traitId_ == 15) return ["b16",                  string(abi.encodePacked(_backgroundPrefix, "WHu/q01Ptwsf/G3fh6tPuVw/q82Pmp0P2eyfzHB43xAAAALklEQVQoz2NUYkADTAzkiLBQyRxqAcZQKvnLmErmvKeOOYyCVHIPlcKHkYjwAQDKIgKV4r2jfwAAAABJRU5ErkJggg=="))];
        if (traitId_ == 16) return ["b17",                  string(abi.encodePacked(_backgroundPrefix, "Wp5f2e4Pxw1P+86Pl60/u05vuV3PrG6fiH2PrCwo+hAAAAKklEQVQoz2NUYkADTAzkiLBQyxwXKplzjzrmMApSxxxqAcbQwRU+xMQXAHk7AzKQ6zO0AAAAAElFTkSuQmCC"))];
        if (traitId_ == 17) return ["b18",                  string(abi.encodePacked(_backgroundPrefix, "V69Pue+Pyp+v3G9vi89/lw+P+V9vqH9fq0+PuE6LnaAAAAK0lEQVQoz2MMZUADTAzkiFALMJZTxz0s76ljDqMgldxDLXPSqOQvF/qFMwAGXgO3kvPGogAAAABJRU5ErkJggg=="))];
        if (traitId_ == 18) return ["b19",                  string(abi.encodePacked(_backgroundPrefix, "Vw/+G8+et6++GH+uG0++2e/OjG+O2V+uSp/euCTsx5AAAALklEQVQoz2NgoA5gVEIXYWIgR4RFkErmuFDJnHtUMseYOuYwUslfjNQK51DCagCoGAJ2TARzWgAAAABJRU5ErkJggg=="))];
        if (traitId_ == 19) return ["b20",                  string(abi.encodePacked(_backgroundPrefix, "W0+9up/daH+sWe/NGV+svG+OG8+dx6+8Fw/771l7DHAAAAKUlEQVQoz2PsYEADTAzkiLC8p445jEpUco/SIPOXIHXMoRZgTKNf+AAAjeMEUekBs6gAAAAASUVORK5CYII="))];
        if (traitId_ == 20) return ["b21",                  string(abi.encodePacked(_backgroundPrefix, "We/LqH+qlw/5qp/cF6+6C8+c2V+rK0+8nG+NSLoVDlAAAALUlEQVQoz2NUYkADTAzkiLBQyRxGQSq5J5Q65lALMBpTyV8uVDLnHpXMIcJfAFHAAnaieR16AAAAAElFTkSuQmCC"))];
        if (traitId_ == 21) return ["b22",                  string(abi.encodePacked(_backgroundPrefix, "WV+pmp/ay0+7fG+Mh6+4Ce/KJw/3a8+b6H+owCjb93AAAALUlEQVQoz2NMY0ADTAzkiLDco5I5LtQxh1qAMZQ67mEUpFL4UMscavnLmLAaAEVRAsjMSfDNAAAAAElFTkSuQmCC"))];
        if (traitId_ == 22) return ["b23",                  string(abi.encodePacked(_backgroundPrefix, "W7/ame+ofC+7Sx/J7Q+Maq+pXJ+byU+3qN/3DQEv19AAAAKUlEQVQoz2PsYEADTAzkiLC8p445jIJUco8Llcy5Rx1zqAUYlYZe+AAAg8EEMkrzZzAAAAAASUVORK5CYII="))];
        if (traitId_ == 23) return ["b24",                  string(abi.encodePacked(_backgroundPrefix, "XQ/am7+ofU+7TJ/J7d+MbD+pXY+by0+3qx/3ASyLiCAAAAKUlEQVQoz2PsYEADTAzkiLC8p445jIJUco8Llcy5Rx1zqAUYlYZe+AAAg8EEMkrzZzAAAAAASUVORK5CYII="))];
        if (traitId_ == 24) return ["b25",                  ""];
        return ["",""];
    }
}