# Copyright 2011 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Makefile for building j2objc.  It's purpose is as a subproject in an Xcode
# project.
#
# Author: Tom Ball

.PHONY: translator dist test

# Force test targets to be run sequentially to avoid interspersed output.
ifeq "$(findstring test,$(MAKECMDGOALS))" "test"
.NOTPARALLEL:
endif

J2OBJC_ROOT = .

include make/common.mk

MAN_DIR = doc/man
MAN_PAGES = $(MAN_DIR)/j2objc.1 $(MAN_DIR)/j2objcc.1

default: dist

install-man-pages: $(MAN_PAGES)
	@mkdir -p $(DIST_DIR)/man/man1
	@install -C -m 0644 $? $(DIST_DIR)/man/man1

annotations_dist:
	@cd annotations && $(MAKE) dist

java_deps_dist:
	@cd java_deps && $(MAKE) dist

translator_dist: translator jre_emul_jar_dist

translator: annotations_dist java_deps_dist
	@cd translator && $(MAKE) dist

jre_emul_jar_dist: annotations_dist
	@cd jre_emul && $(MAKE) emul_jar_dist

jre_emul_dist: translator_dist
	@cd jre_emul && $(MAKE) dist

jre_emul_java_manifest:
	@cd jre_emul && $(MAKE) java_sources_manifest

junit_dist: translator_dist jre_emul_dist
	@cd junit && $(MAKE) dist

jsr305_dist: translator_dist jre_emul_dist java_deps_dist
	@cd jsr305 && $(MAKE) dist

guava_dist: translator_dist jre_emul_dist jsr305_dist
	@cd guava && $(MAKE) dist

cycle_finder_dist: annotations_dist java_deps_dist translator_dist
	@cd cycle_finder && $(MAKE) dist

dist: translator_dist jre_emul_dist junit_dist jsr305_dist guava_dist cycle_finder_dist \
    install-man-pages


clean:
	@rm -rf $(DIST_DIR)
	@cd annotations && $(MAKE) clean
	@cd java_deps && $(MAKE) clean
	@cd translator && $(MAKE) clean
	@cd jre_emul && $(MAKE) clean
	@cd junit && $(MAKE) clean
	@cd cycle_finder && $(MAKE) clean

test_translator: annotations_dist java_deps_dist
	@cd translator && $(MAKE) test

test_jre_emul: jre_emul_dist junit_dist
	@cd jre_emul && $(MAKE) -f tests.mk test

test_jre_cycles: cycle_finder_dist
	@cd jre_emul && $(MAKE) find_cycles

test_guava_cycles: cycle_finder_dist jre_emul_java_manifest
	@cd guava && $(MAKE) find_cycles

test_cycle_finder:
	@cd cycle_finder && $(MAKE) test

test: test_translator test_jre_emul test_jre_cycles test_guava_cycles test_cycle_finder


print_environment:
	@echo Locale: $${LANG}
	@echo `uname -a`
	@echo `xcodebuild -version`
	@echo `xcrun cc -v`
