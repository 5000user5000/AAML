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

/* Modifications:
   - "Add tests"
   - Modified by Charles Tsai in 2024 Fall for AAML lab4.
*/

#include "proj_menu.h"

#include <stdio.h>

#include "cfu.h"
#include "menu.h"

extern int logistic_test(int argc, char** argv);
extern int softmax_test(int argc, char** argv);

namespace {

void run_logistic_test() {
    puts("\nLOGISTIC TEST:");
    logistic_test(0, NULL);
}

void run_softmax_test() {
    puts("SOFTMAX TEST:");
    softmax_test(0, NULL);
}

struct Menu MENU = {
    "Project Menu",
    "project",
    {
        MENU_ITEM('1', "Run logistic tests", run_logistic_test),
        MENU_ITEM('2', "Run softmax tests", run_softmax_test),
        MENU_END,
    },
};

};  // anonymous namespace

extern "C" void do_proj_menu() { menu_run(&MENU); }
