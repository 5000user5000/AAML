/*
 * Copyright 2021 The CFU-Playground Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "functional_cfu_tests.h"

#include <stdio.h>

#include "base.h"
#include "cfu.h"
#include "menu.h"
#include "riscv.h"
#include "perf.h"

namespace {

const uint32_t A_arr[4][64] = {
  {
    0x86898a46, 0x15f8083f, 0x00028629, 0x92110612,
    0x2cff77b3, 0x7b39a3c7, 0xa289108a, 0x580f605c,
    0x7bd9cf9e, 0x92e3f461, 0x6b765c5e, 0x16d5b2f2,
    0xa3f03e00, 0xd95a3a88, 0x9cebcdbe, 0x6bb1d2ba,
    0x4e68b437, 0x700a0f22, 0x6565a14a, 0x2ad0c897,
    0x9e9dc4d7, 0xa754be67, 0x9d6763ba, 0x5ca8d58f,
    0x01c973a0, 0x5d21bc00, 0x5baf8cae, 0x3baec582,
    0xa6ac6f2d, 0xa3a4b030, 0x86adbb7e, 0x22df33b8,
    0xc385ee3f, 0x7ee5173b, 0x454c135b, 0xd1db8e01,
    0x5af8c718, 0x6a249ba9, 0xf65ce540, 0x0018e3b9,
    0x85c11577, 0x23f9c3ee, 0x3aec5ffb, 0x0e5bc72d,
    0xcd8a128c, 0x80c4848b, 0x88111301, 0xd1e13429,
    0xe47ab66b, 0xe961ce2e, 0xc490db04, 0xf9a18856,
    0x2b5eae06, 0x1edebd9a, 0xa1323806, 0x829625bd,
    0xf5b06413, 0x77e853d0, 0x3edf597e, 0x5949c42d,
    0x937e45da, 0x8f9077fe, 0x297e2dbe, 0xa4491f50
  },
  {
    0x2fb798b8, 0x02d38d36, 0x5709dbba, 0x7dbbd868,
    0x7e780d7c, 0x08ab4c95, 0xf492d14d, 0x8e83c714,
    0xc66f208c, 0x75109e93, 0x515b8a4f, 0xbd3771e8,
    0x1c1f5879, 0xc9541060, 0x51389d77, 0x52285cb4,
    0x193a6934, 0x54618fd6, 0x6df28f34, 0xddbab13c,
    0x2a5ebd04, 0xcdd139cd, 0x19ce5dd7, 0x77122d90,
    0x6987798e, 0x45400cb6, 0x4221073f, 0xc684a7a9,
    0xbe501ed1, 0x2d02f30c, 0x323c7567, 0x3faf68eb,
    0xc448555a, 0x14a07ac1, 0x61db667e, 0x19261683,
    0xd81f1bba, 0x5b792839, 0x3f160d85, 0xc9b2141b,
    0xdb12d082, 0xf4189190, 0x21ad92c4, 0x73c172df,
    0x1756d39c, 0xb23e7b50, 0x6ef4021d, 0x0725596e,
    0xf9fa91d4, 0xb469a114, 0x5135c4ae, 0xaccff942,
    0x39ead201, 0x9947dfdd, 0x9562175f, 0x05579a82,
    0xe6b50700, 0x94a0b08e, 0x72ea6eed, 0x570850fa,
    0xa11df75e, 0x974299a1, 0x296d2374, 0xf99f244a
  },
  {
    0x7b5fe1e9, 0x6a4ee08f, 0x38d41276, 0x39f0e81d,
    0x51345145, 0xebf65f53, 0x2806ac62, 0xa1d5fbff,
    0xcb1c2762, 0xd855c013, 0x71053bcc, 0x94bc2a1e,
    0xa643d249, 0x75298e4e, 0x5ece20d3, 0xec5d544d,
    0x5d06de3b, 0x5925bb64, 0x8df27a1d, 0xa0899d0d,
    0x97be50d4, 0x5d78d821, 0xace5ea7e, 0xa1f1da96,
    0xfa08866b, 0xf66d9870, 0x1316a0bb, 0xde43942f,
    0x9194ac80, 0x52b6628b, 0x1fd48913, 0x511f593b,
    0x1c428219, 0xda3d51e4, 0xfe839b0f, 0x302887ca,
    0xad208fe9, 0xcfab3374, 0xa14beca0, 0x6dc59905,
    0x1f100d37, 0xbf40a4d4, 0xd6bddadf, 0x7c1864be,
    0xb995723e, 0x60aafea5, 0x52f0ee33, 0x8647c564,
    0x3edeb7c4, 0xca7c7bf6, 0x58fcb7d3, 0xea4f71fe,
    0xc64700e1, 0x1270ba50, 0x3d718fc1, 0x223283d7,
    0xa70cae84, 0xce16911b, 0xbdccf6b1, 0x2b8aca8a,
    0x2dff062e, 0x84860320, 0x2c0867f1, 0xf8c89b1f
  },
  {
    0x7c9103be, 0xff6e2b5a, 0xb65f71ff, 0xe2d90fe5,
    0x4c911428, 0xdd8a3b6c, 0xc9f4eba6, 0x50fb3c92,
    0x0ecce13b, 0xd905af1d, 0x6698b87c, 0xf6c44d90,
    0x7686feaa, 0xdb156fee, 0xf6b62cf3, 0xa8a67324,
    0xee593332, 0xf904641c, 0x404994e8, 0x6c49568f,
    0x3f0bbf44, 0x8827fad9, 0xed862b72, 0x9c3493b6,
    0x9aec308c, 0x0416af99, 0x07a76690, 0xbd3136af,
    0x65fe62fe, 0x582dea56, 0x072e2cc1, 0x402fb00e,
    0xedfb9f5f, 0x0f2c5b29, 0xb1e2649d, 0x1a8cced5,
    0xe86fe15c, 0x3dde0583, 0x423a1e49, 0xfa69506b,
    0xf60e55f1, 0x2ec0e8a5, 0x3ae6d4ca, 0x17391b25,
    0xf9858cc8, 0x97596234, 0x995a4e3f, 0xd0a34cb8,
    0x38219967, 0xa1011ce4, 0x179b32ea, 0x26aa4cbf,
    0xeeb8bb4e, 0xf20514be, 0xe8a509cc, 0x370feffe,
    0x691648ae, 0xfaaac5f0, 0xb5e58e2f, 0xf295a829,
    0x34e0593f, 0x17935484, 0xa16f16ea, 0xf29a73a0
  }
};

const uint32_t B_arr[4][64] = {
  {
    0x69e499f5, 0x554a8f23, 0x8462d081, 0x96482246,
    0xb7153071, 0x8790926a, 0xe395d4b9, 0x1eb60a84,
    0xfa99551c, 0x8c50f4e0, 0x9f1db3a7, 0xf5873199,
    0x65161c73, 0xbf07aab3, 0xcb86780a, 0x4ee6e66e,
    0x637b99a8, 0x58b17692, 0xb64a332d, 0x030eb955,
    0x8c8e60f6, 0x966a94e2, 0xd397c5f4, 0x4afe29f9,
    0xeca32115, 0x734aa371, 0x59b186a3, 0xed091872,
    0x0e59f401, 0xafa23cea, 0x49819f63, 0x85a4f973,
    0xc5f26563, 0x89a2bcc0, 0x34a44830, 0x7d2912dc,
    0x71c8e90b, 0x7e5b4491, 0xdc73fbe5, 0xecbfdf70,
    0x285ce859, 0x75a172c1, 0xe54e64a6, 0x5e85e2bd,
    0x6db9a265, 0x5c3658c9, 0x1ce77a75, 0xe2ebc2ba,
    0x2b7e843e, 0x88d664a2, 0xb357fdf3, 0x3dbf7bc7,
    0x1893fce9, 0x53a80188, 0x8dd96ca2, 0x26d56bf2,
    0x11b5e54d, 0xacfac74b, 0x7def7c67, 0xb50d3fd4,
    0xd6e0a6d2, 0x98a4df15, 0x6d473cdb, 0x9da60e91
  },
  {
    0x467a4d39, 0xb0958916, 0xbf7a1540, 0xf4f98a12,
    0xea22c7e0, 0x6c2211a1, 0x2ebebf8d, 0x06350165,
    0x3591d081, 0xe2cf779a, 0xc0c5f485, 0x1c9714af,
    0x61c9e92b, 0x4160dd5c, 0x7ec4fdd3, 0xdf70f768,
    0xca4c1a23, 0x569c926a, 0x5518d00b, 0x6b51fc76,
    0x0d199bcc, 0x11dc23a0, 0x3c74b9be, 0xdf382a0d,
    0x4becb874, 0xe748d68d, 0xab21dafb, 0x76f899d1,
    0x3ec66b92, 0xb05e2e7b, 0x982a777e, 0xddee176f,
    0x167a0b94, 0xdce15ddf, 0xb6803ab9, 0xf7419343,
    0x3eeb7b41, 0x2346720b, 0x471e7e8d, 0xa653c8bc,
    0xfaf2ad09, 0xb439d4a0, 0xf5e5055e, 0x4a87dee3,
    0x88070396, 0x261a6f0d, 0xc2bac0e9, 0x4028e5d7,
    0x5aa48fe5, 0xfadbe01e, 0x14182da1, 0x32e71cdc,
    0x0fa96d82, 0xf31d48db, 0xf11f59a6, 0xd5c66647,
    0x20c32bde, 0xf8c45b02, 0x2a0f7d19, 0x0692a614,
    0xbd0f4537, 0x03a09cf6, 0x86fda4f9, 0xc9fb9bd3
  },
  {
    0x7bb1069e, 0xdef54ffb, 0x29b02583, 0x5ed7d7c1,
    0x29eec559, 0xd4fbf54d, 0xe5095733, 0x4b50ad7d,
    0x41ad1895, 0xddd498e7, 0x6b73d39b, 0x83c1277a,
    0x4b5106c7, 0xafcbb5ad, 0xb4921ed3, 0x0cc32fe2,
    0x55b780c3, 0x30218d96, 0xd9168728, 0x740a1de0,
    0x85111d83, 0x4772bde5, 0x8f43a407, 0x43cd8f8a,
    0x30a204ac, 0x257c167b, 0x5dc124bc, 0xffada701,
    0x37ec0595, 0xaad6cfb4, 0x40937939, 0x66938758,
    0xfa8e649c, 0x8ded309f, 0xbbe6b74e, 0x2eee1f71,
    0xc16c4872, 0xa5d26761, 0x7378268e, 0xd8af633d,
    0x9c4639ec, 0x66f59280, 0x36ef384c, 0x467880bd,
    0x1b0142e6, 0xa0fe6762, 0xabe07ab3, 0x3810494d,
    0xa91e55ee, 0xef30fde8, 0x704c3e52, 0x07542e20,
    0xfbd6cd0b, 0xb8fb0f17, 0xfb8e65d1, 0x5b46385e,
    0xe8e7d53d, 0x6367ef1b, 0x2d476f99, 0xbec78d28,
    0xb480f554, 0x33c0d4b7, 0xab4b0980, 0xf8ce3ba9
  },
  {
    0x63ebd52f, 0x02b3edd3, 0x887a4366, 0xb08f66f4,
    0x8ecf7674, 0x588be8c3, 0x18ebd0af, 0x3975e19d,
    0xc3408083, 0x7e048b67, 0x61bd86b1, 0x98de5357,
    0xa0fc59fd, 0x83968f18, 0xd2f62e38, 0x8b71bdcc,
    0x0a36e206, 0xff3b238d, 0x1bb1a6a6, 0x29873f67,
    0x56a5d00c, 0x6a06cd0a, 0xf8135c7d, 0x8e1c4e25,
    0xfffd331b, 0xabf2f2c4, 0x5c6bd552, 0x0de162d8,
    0xf709e4e9, 0xd079c4f6, 0x82b5df1f, 0x53d6a2dd,
    0x7ea14ea5, 0x4cfdc62a, 0xedd9a9c1, 0xe3131e52,
    0xa53c3717, 0x3de1b4f9, 0x1e6b6d9f, 0x0156bc3a,
    0x3a156106, 0x0ccd8b67, 0x4d0811a5, 0x789fe122,
    0x2b709e25, 0x2e929c92, 0xaa18c21b, 0x17b12553,
    0xec54259d, 0x8352bd86, 0x3ecd10cd, 0xeb2400f2,
    0xd0eef235, 0x60240858, 0x1e6401e9, 0xca9b9b87,
    0x92d6fc18, 0x0492e784, 0xb20f2c17, 0x6dd8b816,
    0x497e13cc, 0x3fd7967c, 0x8a217e06, 0x864685d7
  }
};

const uint32_t C_arr_ans[4][256] = {
  {
    0xfffff0bf, 0xffff99b7, 0xffffdb69, 0x00001902, 0xffff59b7, 0xffff8a82, 0x00007eb6, 0xffffb71a, 0xffffc399, 0x00004c7b, 0xffff8ba4, 0xffff8b32, 0x00004ff4, 0xffff4fce, 0x00006443, 0xffffecf0,
    0xffff6b6a, 0x00006012, 0xffffd889, 0xffffdb30, 0xfffff5cf, 0xfffff399, 0x0000167c, 0xffffaf72, 0x000043f0, 0x00003bfa, 0x00003c5e, 0xffff9a06, 0x00007e18, 0xffffb93d, 0x00003ce4, 0x000044aa,
    0x00000baf, 0x0000555c, 0x000028a5, 0x00000f99, 0x00001ec9, 0xffff5860, 0x000062e6, 0xffff99f2, 0xfffffa33, 0x00001c30, 0xffff99af, 0xfffff5a8, 0x0000216b, 0xffff5e5d, 0x000062b6, 0x00003039,
    0x0000297f, 0x0000c2f3, 0xffffb11b, 0xffff824f, 0x000118a5, 0x0000dd7f, 0xffffc9f8, 0xffffb27e, 0xffff92e3, 0xffff586e, 0x000028e5, 0x00001203, 0x00004a88, 0x00009d4c, 0x00000f85, 0x000080e1,
    0x0000276b, 0x0000af7f, 0xffff8ef3, 0xffff3e9f, 0x0000cf8d, 0x000084c2, 0x0000174a, 0xffffef3a, 0xffff7050, 0xffff52b4, 0x00000c47, 0xffffcdb6, 0xffffc878, 0x00006cfd, 0x00004d84, 0x00006e95,
    0x00000160, 0x00003164, 0xffff53a8, 0xffffda56, 0xfffffa2f, 0x0000dc02, 0xffffa85e, 0xffffacfe, 0xffff7d61, 0x00004032, 0x0000456c, 0xffffd1c7, 0xffffb828, 0x00009d20, 0xffff9901, 0xffffe411,
    0x0000f399, 0xffffc1d1, 0x00006335, 0x00009afb, 0xffffc2fa, 0xffffc79c, 0x000063d0, 0xfffff5d2, 0xffff84d2, 0x00005356, 0xfffef5e4, 0x00005225, 0xffff8156, 0xffffbcdc, 0xffffbb90, 0xffffbf32,
    0xfffffb74, 0x00003971, 0xffffaa8f, 0x00005407, 0x00000c0c, 0x00008b38, 0xffffd2df, 0xffffaec5, 0xfffff890, 0xffffe83a, 0x00008e45, 0x00004214, 0x0000235b, 0x0000958d, 0xffff3a97, 0xffffe864,
    0xffffab92, 0x000087ef, 0xffff6b7e, 0x0000063d, 0xfffff2d8, 0x0000642f, 0x000040fc, 0xffff89b0, 0xffffd854, 0xffff96b8, 0xffffd3e3, 0xffff4560, 0xffffea0d, 0xffffeb25, 0x00005a9e, 0xffffb265,
    0xffff74c8, 0xffffb3b0, 0x00001f9c, 0xffff64b7, 0xffffb094, 0xffffdbad, 0x00001942, 0x000052f5, 0xfffff9d0, 0xfffff047, 0x0000056f, 0xffffa519, 0xffffd620, 0x00001c98, 0x000097e4, 0xffffabd5,
    0x00009201, 0x00002505, 0x00002034, 0xfffff22c, 0x000056ff, 0xffffc978, 0x00000bc8, 0xffffbe40, 0xffff2062, 0xfffff480, 0xffffb88f, 0x0000466d, 0x00002af3, 0x00006a1e, 0x00000000, 0x00004958,
    0x00001533, 0xfffff1f0, 0x0000212f, 0xffffcf56, 0x00000087, 0xffffa41c, 0x00002c47, 0x00001d99, 0xffff80a2, 0xffffef48, 0xfffff002, 0x00001fe0, 0xffffc3dd, 0x00005473, 0x00002f01, 0x000015db,
    0xffff6a95, 0x000015ed, 0x00005213, 0x00001258, 0x000065da, 0x00002fda, 0xffff9797, 0x00003de3, 0x0000418b, 0xffffd6f2, 0x00006eb6, 0xffff835c, 0x00008d6f, 0x00004d2e, 0xfffff8af, 0x0000739a,
    0x0000f36f, 0xffffa02e, 0x0000257f, 0x0000cd6d, 0x0000419a, 0xffffca8f, 0xffffd7d6, 0xfffff0ff, 0xffffa51b, 0xffff71a3, 0xffffa85e, 0x00004069, 0xffffd8fa, 0x00004bb9, 0xffffb914, 0xffff8517,
    0xffffffbd, 0xffffc6f2, 0x000018a7, 0xffff908a, 0x00003a29, 0xffff6d0d, 0xffffdca1, 0x00000f27, 0xfffff5d3, 0x0000567a, 0x00002fd7, 0x00002a21, 0xffffbc6b, 0xffffc6de, 0xffffe329, 0x00007b28,
    0x000036c4, 0x00004fa8, 0xffffb559, 0xffffe7ec, 0x000022da, 0xffffb9ab, 0xffffe875, 0xffffcf0e, 0xffffa05f, 0x00001724, 0x00000148, 0xffffb8d1, 0xffffefe9, 0x00001001, 0x000040c3, 0x00003689
  },
  {
    0xffffc8a4, 0x00003ab6, 0xfffffb35, 0xffffcf52, 0xfffff05c, 0x000048a4, 0xffffec8c, 0x0000062a, 0xffffddf2, 0x00000212, 0x00000920, 0x00000d21, 0x00000b23, 0x000000e1, 0x00004ccc, 0xffff71ac, 
    0xfffff209, 0xffffbbd1, 0xfffffce8, 0xffffa927, 0xffffc858, 0xffffd570, 0xffffce8b, 0x000048a9, 0x00001dc5, 0xffff505a, 0xffffeb3e, 0x0000828e, 0xfffff497, 0xffffb54a, 0xffffd817, 0xffffd766, 
    0x00004cb9, 0x00001e61, 0x00000214, 0x00002b1e, 0x00006e81, 0xffff7d29, 0x00002464, 0xffff9957, 0x0000720f, 0xffffcd60, 0x00000400, 0x00002998, 0xffffd795, 0x0000183e, 0xffffb735, 0xfffffd49, 
    0x000027d1, 0xffffa11f, 0xffff2c29, 0x00003193, 0xffffe0ef, 0x00004857, 0x0000401c, 0x00004890, 0xffffdefb, 0xffffce5d, 0x00005438, 0x000051cf, 0xffffb379, 0xfffff731, 0x000034a8, 0x00000aee, 
    0xffffba6c, 0x00002b72, 0xffffe8aa, 0x00000feb, 0xffffce2d, 0x00004f29, 0xffffadb1, 0x0000a4ca, 0xffffb711, 0xfffff77d, 0x0000119d, 0xffffb885, 0xfffff8f9, 0xffffa991, 0x00004608, 0xffffc6b9, 
    0xffffe458, 0x000016bb, 0x00001c13, 0x00004cb1, 0xffff7db2, 0xfffff2ab, 0x0000402c, 0xffffb71a, 0xffff7c96, 0x000021dc, 0x000064be, 0xffffd896, 0xffffdc6e, 0xfffffd1f, 0x00003e0f, 0x00002b33, 
    0x0000d065, 0x0000107a, 0x00004c2f, 0xffffb51a, 0xffff523d, 0x00004b11, 0x0000aa29, 0x00002e06, 0x00000b24, 0x0000a7e0, 0xffffb5c7, 0xffff8ccc, 0xffffb32f, 0x00001040, 0xffffde6c, 0xfffffc7a, 
    0xffffe9ec, 0x000070a5, 0xfffffccf, 0x000046ec, 0xffff859d, 0x0000348d, 0x00005f72, 0x00006aaf, 0x000005a3, 0xffffd46f, 0x00000053, 0x000066a9, 0x00001750, 0x00004d34, 0xffff984a, 0xffffd2d7, 
    0x00002ba0, 0xffff9664, 0xffffefb0, 0xffff79d5, 0x00006895, 0xffffe712, 0xffffe907, 0xffffcb6b, 0xfffff7ae, 0xffff69c9, 0x00001201, 0xffffd83d, 0xffffbc7b, 0x00003ea3, 0x00000be6, 0xffffd712, 
    0x0000a03c, 0x00006e7a, 0x00001e5c, 0x000006f5, 0xffffefb3, 0x000029ac, 0x000071d2, 0xffffc240, 0x00002d7a, 0x00008e85, 0x00004019, 0xffffd519, 0x000001f9, 0xfffffdd4, 0xffffef86, 0xffffb214, 
    0x00001647, 0x0000a220, 0xffffac0b, 0x0000c58f, 0x00005e25, 0x00000599, 0xffffc9a0, 0x0000b52e, 0x00006559, 0xffffd54d, 0x00009acb, 0xffffb062, 0x000009f5, 0xffff8b22, 0xffff157c, 0xffffafcb, 
    0x000007b4, 0x00016c82, 0x00008ca7, 0x000120c9, 0xffff4c0f, 0xffffeb9b, 0x0000a06e, 0x000067c4, 0x00002845, 0xfffff5fa, 0x00004208, 0xffffebc6, 0xffffed03, 0x0000269b, 0xfffefc27, 0xfffff993, 
    0xffff8c76, 0x00001e31, 0x00004106, 0xfffffd47, 0xffffc159, 0xffffd31b, 0xffffc8f5, 0x00000d46, 0x00001c1a, 0xffff36f2, 0xffffab7b, 0x0000801e, 0x00001db5, 0x00001270, 0xffffdb7e, 0x000003c3, 
    0x000065e0, 0xffffee53, 0xffffb2fd, 0x000025b7, 0x000002c8, 0x0000101d, 0x00003568, 0x00001249, 0xffffcf2a, 0xffffce32, 0x0000ac45, 0xffffa945, 0xffffad08, 0x0000119f, 0xfffff9ac, 0x00000fd0, 
    0xffffedc5, 0xffff65d6, 0xfffff2b3, 0xffff5f3c, 0x000003bf, 0xffffc4a3, 0xfffff74e, 0xffffd7c8, 0x00004f6f, 0xffff7cf1, 0xffff94a2, 0x000080b5, 0xffffe3f2, 0x0000709b, 0xfffffd66, 0x0000191a, 
    0x00004b37, 0xffff6cb9, 0xffff752c, 0xffffc84f, 0x00003e7b, 0xffffc026, 0x000037cf, 0x00004306, 0x00002e0f, 0xffffcb38, 0xffffd909, 0x00000ffa, 0xffffa764, 0x0000650c, 0xffffb701, 0xffffe0de
  },
  {
    0x00003b32, 0xffffa65e, 0x0000071c, 0xffff2ed5, 0xffffe565, 0xffffe6ac, 0xfffff801, 0xffffb0a5, 0xffff831c, 0xffffb940, 0x0000bd75, 0x00002f45, 0x000003a4, 0x0000689d, 0x0000848f, 0xffff278f,
    0x00004bd2, 0xffffe649, 0xfffff08e, 0xffff9a19, 0x000030c1, 0x00000922, 0xffffafbc, 0xffffca8f, 0x000005eb, 0xffffed74, 0x00006279, 0xffffc9d0, 0xffffebdf, 0xffffd41c, 0x00001f3b, 0xffffd90c,
    0x00001b4d, 0xfffff2e6, 0x00001758, 0x00004197, 0x00005281, 0xffffbb78, 0x00001481, 0x000006e7, 0xffffc820, 0x00001a7e, 0x00001e05, 0x00008b8e, 0xffffc446, 0x00001ea7, 0xfffff7cb, 0xfffff7c8,
    0x0000133d, 0xffffa540, 0xfffffa10, 0xffffdb96, 0xffffb3b6, 0x00000ed2, 0xffff8358, 0xffffed76, 0xffffff29, 0x000076aa, 0x00002ca6, 0x0000898c, 0x00001c77, 0xffff708f, 0x000002ea, 0x00005eb4,
    0xffff8ff0, 0xffffb790, 0x000025b7, 0xffffbdc2, 0x00006723, 0xffffd1f1, 0xffffdcee, 0x000042c1, 0xffff9b84, 0xffff89ca, 0x0000633a, 0xffffbd7f, 0xffff9a94, 0x00001a73, 0xfffff8cc, 0xffff3a64,
    0xffff9130, 0xffffed63, 0x000010d4, 0x00005ef3, 0x00003a1e, 0x00005b05, 0xffffacdb, 0x000085d1, 0x00001e72, 0xffffee19, 0xffff8349, 0xffff9271, 0x000007d1, 0x000044a8, 0xffffe8d9, 0xfffffc4b,
    0xffffdea0, 0xfffffda3, 0x00000279, 0x000010f9, 0xffff00f2, 0x0000350d, 0xffffadd2, 0x00004b6f, 0xffffc584, 0x000003af, 0xffffd06a, 0x0000e004, 0x00007ecb, 0xffffa29f, 0x00000363, 0xffffecf3,
    0xffffb422, 0xffff3d1a, 0x0000946b, 0xffffe837, 0x000025cf, 0x00004d9f, 0xffff8f79, 0x0000a7b6, 0x00003a93, 0x00005357, 0xffff98a0, 0xffff0447, 0xffffd15d, 0x00003453, 0x00001c6f, 0xffffe2a3,
    0xffffba4e, 0xffffb6ae, 0xffffcb92, 0x00001783, 0x00001a0a, 0xffff6901, 0x00001572, 0xffffc757, 0xffff955a, 0xffffbf3b, 0xffffef71, 0x0000048c, 0xfffffed8, 0x000058e9, 0xffffa06c, 0x00002b0b,
    0xffffe459, 0xffffaafe, 0x00003d93, 0x0000438f, 0x00000108, 0x00000867, 0xfffff568, 0x00005b8f, 0x000082ab, 0x00005294, 0xffffc4aa, 0xffff41f4, 0xffffc7c8, 0xfffffec6, 0xfffff7da, 0xffffb776,
    0xffff38f2, 0x00005899, 0x00008019, 0x00006311, 0xffffd452, 0x00000f42, 0x00003d53, 0xffffef3a, 0xffffe446, 0x00005b2c, 0xffffa95a, 0xffff7e91, 0xffff65e8, 0xffff3fae, 0xffff55d5, 0x00000ab4,
    0x00003d31, 0xffffeada, 0x0000280f, 0xffffdd0b, 0x000097e9, 0xffffca41, 0xfffffd0d, 0x000018f3, 0xffff9c59, 0xffffa11a, 0x00006eb6, 0x00003a04, 0xffff9e60, 0xffffffab, 0x000017ff, 0x00001a0e,
    0x00000857, 0xfffffb63, 0x00005eb3, 0x0000422a, 0x00000ca2, 0x000007ed, 0xffffb018, 0x000054b3, 0x00004874, 0xffffd4b4, 0xffffc961, 0xffffa467, 0xffffc51a, 0xfffff6b7, 0x000047ad, 0x00004097,
    0x00003ba5, 0x00002709, 0x000022fb, 0x00006474, 0x00000ffb, 0x0000c876, 0xffffe98f, 0xffffaef9, 0xffffc19d, 0xfffffab1, 0x00006529, 0xffffe541, 0xfffff629, 0x00003954, 0x000053cb, 0x0000433e,
    0xffffcbc2, 0x00000fd6, 0x00002475, 0xffffc786, 0x000009d9, 0xfffff978, 0x0000f52b, 0xffffdbae, 0xffff963c, 0xffffd885, 0x00000d0f, 0x00000fcf, 0xffffa5f4, 0x0000422c, 0xffffb18e, 0xffff9d2e,
    0xffffc328, 0x00003705, 0xffffd1de, 0x00001cdb, 0xfffffe76, 0x000089c6, 0x00004b27, 0x0000584e, 0xfffff5d8, 0xffffa2c5, 0x00000e79, 0x00004875, 0x00000168, 0xffffef55, 0xffffeee8, 0xffffee71
  },
  {
    0x00005ecd, 0xffffdb2d, 0x0000186d, 0xffffe98a, 0xfffffd98, 0x0000599d, 0x00000ea0, 0x000032b8, 0x00004019, 0x0000629e, 0x00001fca, 0xffffd987, 0xffffd1c6, 0x0000303b, 0x00003de7, 0xffffc437, 
    0x000015f7, 0x00005b06, 0xfffffaf5, 0x00001c1d, 0xffff892d, 0x00002086, 0x00003a69, 0xffff7964, 0xffffaa68, 0xffffe8c6, 0xffffbd97, 0xfffff074, 0x00002152, 0xffff8301, 0xffffd1cf, 0xffffc372,
    0xffff11a6, 0x0000231e, 0x00004821, 0x00002b63, 0x0000134b, 0xffffd1df, 0xffffbada, 0xffffaacb, 0x00001ba8, 0xffff9570, 0xffff92f8, 0x0000012a, 0x00001a9a, 0x00000b5e, 0xffff7be5, 0x00001a3a,
    0x00005a17, 0xffffa8b3, 0xffff7406, 0xffffbc08, 0x00009c14, 0x000026fa, 0xffff7b6b, 0xffffd057, 0xfffff35a, 0xffffca78, 0x0000034f, 0xffffff59, 0xffff725b, 0xfffffb8a, 0x00002583, 0x00005579,
    0xffff24ad, 0xffffd4a4, 0x00007c2d, 0x00008e45, 0x00002369, 0xffffbad9, 0xffff8497, 0xffffead0, 0xffff9e6d, 0xfffffc83, 0xffffd542, 0x000003af, 0x0000037b, 0x000054ee, 0x0000006b, 0x000007cd,
    0xffff9910, 0x00001462, 0x00005497, 0x00007afa, 0xffffe2dc, 0xffffa836, 0xffffc397, 0xffffa41e, 0x00000bd0, 0xffff7bc8, 0xffff8c59, 0x00004f5c, 0x00000de7, 0xffffd24b, 0xffffca5e, 0xffffcaa5,
    0x000012f4, 0xffff2990, 0x0000144b, 0xffff9ac2, 0x00002e0d, 0x000049f6, 0x00006220, 0x00005768, 0x000084f6, 0x00003587, 0x00004f0b, 0xffffcb82, 0xffffda58, 0x0000cded, 0x00006af8, 0x00001664,
    0xffffcbbc, 0xffffe214, 0x0000275a, 0x00002e57, 0x00001b15, 0x00004fd3, 0xffffc969, 0xffffe62a, 0xffffd9e2, 0x000009fa, 0x00005822, 0xffff694b, 0x00004e4e, 0x0000800f, 0xffffdd03, 0x00004006,
    0x0000be2e, 0xffffb2e3, 0xffffdd18, 0xffffa3f9, 0x00004aae, 0x000020fa, 0x00006785, 0x000041a3, 0x00004329, 0x00003fb9, 0x00004118, 0x0000192f, 0x000030ec, 0x00001907, 0x000008b9, 0xffffdf3a,
    0xffffe994, 0xffffefd8, 0xfffff1da, 0x00001b72, 0xffff8877, 0x00003ce8, 0x00004b04, 0x000015cb, 0xffffd96e, 0x00001785, 0x000012dd, 0xffffa2a6, 0xffffcb15, 0xffff98ea, 0xffffde16, 0x000045b6,
    0xffff6f4a, 0x00006c9a, 0xffff9673, 0xffffc07b, 0xffffaea3, 0x000000fa, 0x0000040d, 0xffffb874, 0xfffff5dc, 0xffffc2ad, 0xffffb891, 0xfffffe2d, 0xffff94aa, 0xffff9d06, 0xffff855e, 0x00000a66,
    0xfffff01f, 0xffffef42, 0x00002800, 0x00000db0, 0xffff7a0e, 0x000037eb, 0x00007aa9, 0x000044fe, 0xffffef60, 0x00003dc9, 0x00006f19, 0xffffbbd2, 0xffffa94d, 0x00000565, 0xffffe74b, 0xffffe750,
    0xffffd17e, 0x000059f5, 0xfffff1a0, 0xffffdc2e, 0xfffff17b, 0xfffff370, 0x00001ece, 0x00001584, 0x00001fb9, 0x0000069f, 0x00002a05, 0xffffff43, 0x000046ce, 0xffffc9e9, 0xffffd572, 0xfffff5fb,
    0x0000c124, 0x00002258, 0x00000562, 0xffffb0a1, 0xffff9a19, 0x0000254b, 0x000013d6, 0x000014da, 0xffffb138, 0x00004fa0, 0x00002e66, 0xffffff2a, 0xffff9671, 0x00001415, 0x0000afec, 0x00000439,
    0xffff1351, 0x00003a33, 0x000009c3, 0xffff96e3, 0xfffff327, 0xffffc417, 0xffffd094, 0xffffe3d0, 0xffffca92, 0x0000203c, 0xffffc784, 0x00003e66, 0xffffe3d7, 0x00004f07, 0xffffb93e, 0x0000226b,
    0x00006910, 0x0000071d, 0x00008e45, 0x000079c4, 0x00001223, 0x000001c0, 0x000007aa, 0xfffff15e, 0x000002eb, 0x0000374d, 0x00002a80, 0xffffecc5, 0x00002a0b, 0x0000183d, 0x000069ce, 0xffffba56
  }
};
const uint8_t K = 16, M = 16, N = 16; 
uint32_t error_ct = 0;



void do_matmul_num(int test_num) {
  // place your answer in this array!
  uint32_t C_arr[16][16];

  // =====================================================
  // Implement your design here, 
  // and DO NOT MODIFY ANYTHING "ABOVE" THIS LINE !!
  // ===================================================== 

  /**
    All inputs are 16*16 signed int8 matrix, outputs are 16*16 signed int32.
    1. Pass data to CFU.
    2. Pass matrix parameters to CFU.
    3. Receive data from CFU and place it to `C_arr`.
        - you may use __asm volatile("NOP") to wait some cycles if unstable.
  */ 
    printf("Reset\n");
    cfu_op0(/* funct7= */ 1, /* in0= */ 0, /* in1= */ 0); // reset
    cfu_op0(/* funct7= */ 2, /* in0= */ K, /* in1= */ K); // Set parameter K
    cfu_op0(/* funct7= */ 4, /* in0= */ M, /* in1= */ M); // Set parameter M
    cfu_op0(/* funct7= */ 6, /* in0= */ N, /* in1= */ N); // Set parameter N

    int K_ret =  cfu_op0(/* funct7= */ 3, /* in0= */ K, /* in1= */ K); // Read parameter K
    int M_ret =  cfu_op0(/* funct7= */ 5, /* in0= */ M, /* in1= */ M); // Read parameter M
    int N_ret =  cfu_op0(/* funct7= */ 7, /* in0= */ N, /* in1= */ N); // Read parameter N
    printf("Set K: %d, Return K: %d\n", K, K_ret);
    printf("Set M: %d, Return M: %d\n", M, M_ret);
    printf("Set N: %d, Return N: %d\n", N, N_ret);

    // set Buffer A
    for (int idx = 0; idx < 64; idx++) {
        cfu_op0(/* funct7= */ 8, /* in0= */ idx, /* in1= */ A_arr[test_num][idx]); // Read global bufer A
        int32_t ret = cfu_op0(9, idx, 0);
        printf("Set Buffer A, in: %lX, \t\taddr: %x, \t\tout: %lX\n", A_arr[test_num][idx], idx, ret);
    }
    // set Buffer B
    for (int idx = 0; idx < 64; idx++) {
        cfu_op0(/* funct7= */ 10, /* in0= */ idx, /* in1= */ B_arr[test_num][idx]); // Read global bufer B
        int32_t ret2 = cfu_op0(11, idx, 0);
        printf("Set Buffer B, in: %lX, \t\taddr: %x, \t\tout: %lX\n", B_arr[test_num][idx], idx, ret2);
    }

    // Start CFU
      printf("In valid\n");
      int cnt = 0;
      int cycle = cfu_op0(12, 0, 0); // reset
      printf("cycle = %d\n", cycle);

      // Check Status
      while(1) {
        int busy = cfu_op0( 13, 0, 0); 
        cnt++;
        if (!busy)
          break;
        if(cnt > 50)
          break;
      }
      printf("busy cycle = %d\n", cnt);

     // Get Buffer C
    for (int idx = 0; idx < 64; idx++) {
        // if (idx + 3 >= 64) {
        //     break; // 防止越界访问
        // }
        uint32_t c_ret = cfu_op0(14, idx, 0);
        uint32_t c_ret1 = cfu_op0(15, idx, 0);
        uint32_t c_ret2 = cfu_op0(16, idx, 0);
        uint32_t c_ret3 = cfu_op0(17, idx, 0);
        // printf ("Return C: %08lX \n", c_ret);
        printf ("Return C: %08lX, %08lX, %08lX, %08lX \n", c_ret, c_ret1, c_ret2, c_ret3);
        // C_arr[test_num][idx] = cfu_op0(14, idx , 0);
        // C_arr[test_num][idx+1] = cfu_op0(15, idx , 0);
        // C_arr[test_num][idx+2] = cfu_op0(16, idx , 0);
        // C_arr[test_num][idx+3] = cfu_op0(17, idx , 0);
    }

  // =====================================================
  // DO NOT MODIFY ANYTHING "BELOW" THIS LINE !!
  // =====================================================

  for (uint32_t i = 0; i < 16; i++) {
    for (uint32_t j = 0; j < 16; j++) {
      if (C_arr[i][j] != C_arr_ans[test_num][(i<<4)+j]) {
        error_ct++;
	printf("*** %ld error(s) @ pattern no. %d\n ---> golden C_arr[%02ld][%02ld] = %08lX, your C_arr[%02ld][%02ld] = %08lX\n",
          error_ct, test_num, i, j, C_arr_ans[test_num][(i<<4)+j], i, j, C_arr[i][j]);
      }
    }
  }

  // printf("check: %08lX, %08lX\n", C_arr[255], C_arr_ans[test_num][255]);
}

void do_matmul_cfu_1(void) {
  error_ct = 0;
  perf_reset_all_counters();
  perf_enable_counter(0);
  do_matmul_num(0);
  perf_disable_counter(0);
  if (error_ct == 0) {
    printf("*** PASSED\n");
  }
  perf_print_all_counters(); 
}

void do_matmul_cfu_2(void) {
  error_ct = 0;
  perf_reset_all_counters();
  perf_enable_counter(0);
  do_matmul_num(1);
  perf_disable_counter(0);
  if (error_ct == 0) {
    printf("*** PASSED\n");
  }
  perf_print_all_counters(); 
}

void do_matmul_cfu_3(void) {
  error_ct = 0;
  perf_reset_all_counters();
  perf_enable_counter(0);
  do_matmul_num(2);
  perf_disable_counter(0);
  if (error_ct == 0) {
    printf("*** PASSED\n");
  }
  perf_print_all_counters(); 
}

void do_matmul_cfu_4(void) {
  error_ct = 0;
  perf_reset_all_counters();
  perf_enable_counter(0);
  do_matmul_num(3);
  perf_disable_counter(0);
  if (error_ct == 0) {
    printf("*** PASSED\n");
  }
  perf_print_all_counters(); 
}

void do_matmul_cfu(void) {
  error_ct = 0;
  perf_reset_all_counters();
  perf_enable_counter(0);
  for (int i = 0; i < 4096; i++) {
    do_matmul_num(i&3);
  }
  perf_disable_counter(0);
  if (error_ct == 0) {
    printf("*** ALL PASSED\n");
  } else {
    printf("*** FAIL: %ld error(s)\n", error_ct);
  }
  perf_print_all_counters();
}

struct Menu MENU = {
    "Tests for Functional CFUs",
    "functional",
    {
        MENU_ITEM('h', "Matmul 16*16 int8 w/ pattern 1", do_matmul_cfu_1),
        MENU_ITEM('e', "Matmul 16*16 int8 w/ pattern 2", do_matmul_cfu_2),
        MENU_ITEM('l', "Matmul 16*16 int8 w/ pattern 3", do_matmul_cfu_3),
        MENU_ITEM('p', "Matmul 16*16 int8 w/ pattern 4", do_matmul_cfu_4),
        MENU_ITEM('!', "Matmul 16*16 int8 4096 times w/ 4 patterns rotating", do_matmul_cfu),
        MENU_END,
    },
};

};  // anonymous namespace

extern "C" void do_functional_cfu_tests() { menu_run(&MENU); }
