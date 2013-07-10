# KJess

* [Homepage](https://github.com/copiousfreetime/kjess/)
* [Github Project](https://github.com/copiousfreetime/kjess)
* email jeremy at copiousfreetime  dot org

## DESCRIPTION

KJess is a pure ruby Kestrel client that supports Kestrel's Memcache style
protocol.

## FEATURES

A pure ruby native client to Kestrel.

## Examples

    client = Kestrel::Client.new( 'k.example.com' )
    client.set( 'my_queue', 'item' )   # put an 'item' on 'my_queue'
    i = client.reserve( 'my_queue' )   # get an item off 'my_queue' with
                                       # Reliable Read

    # do something with the item pulled off the queue

    client.close( 'my_queue' )         # confirm with Kestrel that the item
                                       # retrieved was processed

## ISC LICENSE

<http://opensource.org/licenses/isc-license.txt>

Copyright (c) 2012 Jeremy Hinegardner

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
