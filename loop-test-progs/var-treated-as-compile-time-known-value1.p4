/*
Copyright 2024 Andy Fingerhut

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata_t {
}

struct headers_t {
    ethernet_t ethernet;
}

parser parserImpl(packet_in packet,
                  out headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t stdmeta)
{
    state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control ingressImpl(inout headers_t hdr,
                    inout metadata_t meta,
                    inout standard_metadata_t stdmeta)
{
    bit<8> n = hdr.ethernet.srcAddr[15:8];
    bit<3> i = 0;
    apply {
        {
            // In the 2024-Jul-01 P4 language design work group
            // meeting, Jonathan DiLorenzo asked some questions that I
            // _believe_ could be the same as the following question:

            // Should a P4 variable be treated as if its value is a
            // compile-time known value, if the compile can prove that
            // it can have one and only one value at a specific point
            // of the program?

            // The question was raised in the context of a discussion
            // about loops in P4, but since the discussion was also
            // about a P4 program that resulted from unrolling all
            // loops, it seems to me that the question is relevant for
            // a program like this one that has no loops.

            // i was initialized to 0 above, and there are no
            // statements afterwards that could change it, so one
            // could imagine a sufficiently sophisticated compiler
            // that could determine that the expression i was always 0
            // at this point during the execution.
            n[i:i] = 1;
            
            hdr.ethernet.srcAddr[15:8] = n;
            stdmeta.egress_spec = 1;
        }
    }
}

control egressImpl(inout headers_t hdr,
                   inout metadata_t meta,
                   inout standard_metadata_t stdmeta)
{
    apply {
    }
}

control deparserImpl(packet_out packet,
                     in headers_t hdr)
{
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

control updateChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch(parserImpl(),
         verifyChecksum(),
         ingressImpl(),
         egressImpl(),
         updateChecksum(),
         deparserImpl()) main;
