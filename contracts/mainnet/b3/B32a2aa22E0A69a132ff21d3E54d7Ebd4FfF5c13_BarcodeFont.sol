// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract BarcodeFont {
    // based off the very excellent Libre Barcode 39

    /*
  
    This Font Software is licensed under the SIL Open Font License, Version 1.1.
    This license is copied below, and is also available with a FAQ at:
    http://scripts.sil.org/OFL


    -----------------------------------------------------------
    SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
    -----------------------------------------------------------

    PREAMBLE
    The goals of the Open Font License (OFL) are to stimulate worldwide
    development of collaborative font projects, to support the font creation
    efforts of academic and linguistic communities, and to provide a free and
    open framework in which fonts may be shared and improved in partnership
    with others.

    The OFL allows the licensed fonts to be used, studied, modified and
    redistributed freely as long as they are not sold by themselves. The
    fonts, including any derivative works, can be bundled, embedded, 
    redistributed and/or sold with any software provided that any reserved
    names are not used by derivative works. The fonts and derivatives,
    however, cannot be released under any other type of license. The
    requirement for fonts to remain under this license does not apply
    to any document created using the fonts or their derivatives.

    DEFINITIONS
    "Font Software" refers to the set of files released by the Copyright
    Holder(s) under this license and clearly marked as such. This may
    include source files, build scripts and documentation.

    "Reserved Font Name" refers to any names specified as such after the
    copyright statement(s).

    "Original Version" refers to the collection of Font Software components as
    distributed by the Copyright Holder(s).

    "Modified Version" refers to any derivative made by adding to, deleting,
    or substituting -- in part or in whole -- any of the components of the
    Original Version, by changing formats or by porting the Font Software to a
    new environment.

    "Author" refers to any designer, engineer, programmer, technical
    writer or other person who contributed to the Font Software.

    PERMISSION & CONDITIONS
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of the Font Software, to use, study, copy, merge, embed, modify,
    redistribute, and sell modified and unmodified copies of the Font
    Software, subject to the following conditions:

    1) Neither the Font Software nor any of its individual components,
    in Original or Modified Versions, may be sold by itself.

    2) Original or Modified Versions of the Font Software may be bundled,
    redistributed and/or sold with any software, provided that each copy
    contains the above copyright notice and this license. These can be
    included either as stand-alone text files, human-readable headers or
    in the appropriate machine-readable metadata fields within text or
    binary files as long as those fields can be easily viewed by the user.

    3) No Modified Version of the Font Software may use the Reserved Font
    Name(s) unless explicit written permission is granted by the corresponding
    Copyright Holder. This restriction only applies to the primary font name as
    presented to the users.

    4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
    Software shall not be used to promote, endorse or advertise any
    Modified Version, except to acknowledge the contribution(s) of the
    Copyright Holder(s) and the Author(s) or with their explicit written
    permission.

    5) The Font Software, modified or unmodified, in part or in whole,
    must be distributed entirely under this license, and must not be
    distributed under any other license. The requirement for fonts to
    remain under this license does not apply to any document created
    using the Font Software.

    TERMINATION
    This license becomes null and void if any of the above conditions are
    not met.

    DISCLAIMER
    THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
    OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
    DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
    OTHER DEALINGS IN THE FONT SOFTWARE.
  
  */

    string public constant font =
        "data:application/font-woff2;charset=utf-8;base64,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";
}