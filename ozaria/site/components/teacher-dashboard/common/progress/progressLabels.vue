<script>
import IconHelp from '../../common/icons/IconHelp'
import ProgressDot from '../../common/progress/progressDot'

export default {
    components: {
      IconHelp,
      ProgressDot
    },
    props: {
      showReviewLabels: {
        type: Boolean,
        default: false
      }
    }
  }
</script>

<template>
  <div class="progress-labels">
    <div class="img-subtext">
      <div class="dot-border"><div class="dot green-dot"></div></div>
      <span>{{ $t('courses.complete') }}</span>
    </div>
    <div class="img-subtext">
      <div class="dot-border"><div class="dot teal-dot"></div></div>
      <span>{{ $t('teacher.in_progress') }}</span>
    </div>
    <div class="img-subtext">
      <div class="dot-border"><div class="dot assigned-dot"></div></div>
      <span>{{ $t('teacher.assigned') }}</span>
    </div>
    <div class="img-subtext" v-if="showReviewLabels">
      <progress-dot
        :is-locked="true"
        class="dot-border"
      />
      <span>{{ $t("common.locked") }}</span>
    </div>
    <div class="img-subtext" v-if="showReviewLabels">
      <div class="dot-border concept-flag-border"><div class="dot green-dot"></div></div>
      <span>{{ $t('teacher_dashboard.concept_flag') }}</span>
    </div>
    <div class="img-subtext" v-if="showReviewLabels">
      <div class="dot-border"><div class="dot"><img src="/images/ozaria/teachers/dashboard/svg_icons/IconSkippedLevel.svg"></div></div>
      <span>{{ $t('teacher_dashboard.skipped') }}</span>
    </div>
    <div class="img-subtext" v-if="showReviewLabels">
      <div class="dot-border"><div class="dot"><img src="/images/ozaria/teachers/dashboard/svg_icons/IconOptionalLevel.svg"></div></div>
      <span>{{ $t('teacher_dashboard.optional') }}</span>
    </div>

    <div v-if="showReviewLabels" class="help-container">
      <v-popover
        popover-class="teacher-dashboard-tooltip lighter-p large-width"
        trigger="hover"
      >
        <!-- Triggers the tooltip -->
        <icon-help />
        <!-- The tooltip -->
        <template slot="popover">
          <div>
            <h3 style="margin-bottom: 15px;">{{ $t('teacher_dashboard.support_learning') }}</h3>
            <div class="supportGrid">
              <div class="top-row">
                <p>{{ $t('teacher.all_students') }}</p>
              </div>
              <div class="top-row">
                <div class="dot-border concept-flag-border"><div class="dot green-dot"></div></div>
              </div>
              <div class="description top-row">
                <p>{{ $t('teacher_dashboard.concept_flag_desc') }}</p>
              </div>
              <div class="bottom-row"><p> {{ $t('courses.student') }} </p></div>
              <div class="bottom-row"><div class="dot-border concept-flag-border"><div class="dot green-dot"></div></div></div>
              <div class="description bottom-row">
                <p> {{ $t('teacher_dashboard.concept_flag_desc2') }} </p>
              </div>
            </div>
            <p style="margin-top: 20px; font-family: Monaco, Menlo, Ubuntu Mono, Consolas, source-code-pro, monospace; font-size: 12px;">
              {{ $t('teacher_dashboard.click_progress_dot_tip') }}
            </p>
          </div>
        </template>
      </v-popover>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.progress-labels {
  // ensure spacers are equal size
  flex: 0.5 0.5 0px;

  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: flex-start;

  & > div {
    width: 50px;
    margin: 0 10px;
  }

  & > div.help-container {
    width: 26px;

    ::v-deep .v-popover {
      display: flex;
      .trigger {
        line-height: 19px;
      }
    }
  }
}

.img-subtext {
  width: 100%;
  height: 100%;

  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  @include font-p-4-paragraph-smallest-gray;
  font-size: 10px;
  line-height: 11px;
  text-align: center;
  white-space: nowrap;
}

.dot-border {
  width: 22px;
  height: 22px;

  margin-bottom: 6px;

  display: flex;
  justify-content: center;
  align-items: center;

  border-radius: 3px;
}

.dot {
  width: 14px;
  height: 14px;
  border-radius: 8px;
}

.green-dot {
  background-color: #2dcd38;
}

.teal-dot {
  background-color: #1ad0ff;
}

.assigned-dot {
  border: 1.5px solid #c8cdcc;
}

.concept-flag-border {
  border: 1px solid #eb003b;
}

.time-flag-border {
  border: 1px solid #828282;
}

.supportGrid {
  display: grid;
  grid-template-columns: 0.4fr 45px 1fr;
  grid-template-rows: 47px 47px;
  justify-content: center;
  align-items: center;

  .top-row, .bottom-row {
    width: 100%;
    height: 100%;

    display: flex;
    align-items: center;
    justify-content: center;

    padding: 0 10px;
    text-align: left;

    /* Required so that we don't have thick borders between cells. */
    &:not(:nth-child(3n+1)) {
      border-left: unset;
    }

    &:nth-child(3n+1) {
      justify-content: unset;
    }
  }

  .top-row {
    background: #fff9e3;
    border: 0.5px solid #c2a957;
  }

  .bottom-row {
    border: 0.5px solid #d8d8d8;
    border-top: unset;
  }

  .description p {
    font-size: 13px;
    color: #545b64;
  }
}
</style>
